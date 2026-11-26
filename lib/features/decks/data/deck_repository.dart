import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../flashcards/data/mappers/firestore_study_mapper.dart';
import '../../flashcards/domain/models/deck.dart';
import '../../flashcards/domain/models/flashcard.dart';
import '../../flashcards/data/mappers/study_progress_key.dart';
import '../../flashcards/domain/models/study_progress.dart';

class DeckRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final String? _scopedUserId;

  DeckRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? scopedUserId,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _scopedUserId = scopedUserId;

  static const _serverOnly = GetOptions(source: Source.server);
  static const maxSessionResults = 10;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Authentication required.');
    }

    if (_scopedUserId != null && user.uid != _scopedUserId) {
      throw StateError('Repository belongs to a different user.');
    }

    return user.uid;
  }

  void _requireSameUser(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Authentication changed during the operation.');
    }
  }

  String _requiredText(String value, String field) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('$field cannot be empty.');
    }

    return clean;
  }

  String _documentId(String id) {
    if (id.trim().isEmpty || id.contains('/') || id == '.' || id == '..') {
      throw ArgumentError('Invalid document ID.');
    }

    return id;
  }

  DocumentReference<Map<String, dynamic>> _deckRef(String deckId) {
    return _db.collection('decks').doc(_documentId(deckId));
  }

  Future<DocumentReference<Map<String, dynamic>>> _requireOwnedDeck(
    String deckId,
    String uid,
  ) async {
    _requireSameUser(uid);

    final ref = _deckRef(deckId);
    final snapshot = await ref.get(_serverOnly);

    _requireSameUser(uid);

    if (!snapshot.exists || snapshot.data()?['ownerId'] != uid) {
      throw StateError('Deck not found or access denied.');
    }

    return ref;
  }

  Query<Map<String, dynamic>> _progressQuery({
    required String uid,
    required String deckId,
  }) {
    return _db
        .collection('progress')
        .where('userId', isEqualTo: uid)
        .where('deckId', isEqualTo: deckId);
  }

  DocumentReference<Map<String, dynamic>> _progressRef({
    required String uid,
    required String deckId,
    required String cardId,
  }) {
    final id = StudyProgressKey.build(
      userId: uid,
      deckId: deckId,
      cardId: cardId,
    );

    return _db.collection('progress').doc(id);
  }

  Future<void> createDeck({
    required String subjectId,
    required String title,
    String description = '',
  }) async {
    final uid = _uid;
    final cleanSubject = _requiredText(subjectId, 'Subject ID');
    final cleanTitle = _requiredText(title, 'Title');

    await _db.collection('decks').add({
      'ownerId': uid,
      'subjectId': cleanSubject,
      'title': cleanTitle,
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyDecks() {
    return _db
        .collection('decks')
        .where('ownerId', isEqualTo: _uid)
        .snapshots();
  }

  Future<List<Deck>> fetchDecks() async {
    final uid = _uid;

    final snapshot = await _db
        .collection('decks')
        .where('ownerId', isEqualTo: uid)
        .get(_serverOnly);

    _requireSameUser(uid);

    final decks = snapshot.docs.map((document) {
      if (document.metadata.hasPendingWrites) {
        throw StateError('Deck changes are awaiting confirmation.');
      }

      final deck = FirestoreStudyMapper.deckFromMap(
        id: document.id,
        data: document.data(),
      );

      if (deck.ownerId != uid) {
        throw StateError('Unexpected deck owner.');
      }

      return deck;
    }).toList();

    decks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return List<Deck>.unmodifiable(decks);
  }

  Future<void> updateDeck({
    required String deckId,
    required String title,
    String description = '',
  }) async {
    final uid = _uid;
    final cleanTitle = _requiredText(title, 'Title');

    final ref = await _requireOwnedDeck(deckId, uid);

    _requireSameUser(uid);

    await ref.update({
      'title': cleanTitle,
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDeck(String deckId) async {
    final uid = _uid;
    final deckRef = _deckRef(deckId);

    // Prevent further card and progress writes.
    await _db.runTransaction<void>((transaction) async {
      _requireSameUser(uid);

      final snapshot = await transaction.get(deckRef);

      _requireSameUser(uid);

      if (!snapshot.exists || snapshot.data()?['ownerId'] != uid) {
        throw StateError('Deck not found or access denied.');
      }

      if (snapshot.data()?['deleting'] != true) {
        transaction.update(deckRef, {
          'deleting': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    // Remove progress in small batches.
    while (true) {
      _requireSameUser(uid);

      final progress = await _progressQuery(
        uid: uid,
        deckId: deckId,
      ).limit(10).get(_serverOnly);

      _requireSameUser(uid);

      if (progress.docs.isEmpty) break;

      final batch = _db.batch();

      for (final document in progress.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();
    }

    // Remove nested flashcards.
    while (true) {
      _requireSameUser(uid);

      final cards = await deckRef
          .collection('cards')
          .limit(10)
          .get(_serverOnly);

      _requireSameUser(uid);

      if (cards.docs.isEmpty) break;

      final batch = _db.batch();

      for (final document in cards.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();
    }

    _requireSameUser(uid);

    // Delete the parent only after cleanup.
    await deckRef.delete();
  }

  Future<List<Flashcard>> fetchFlashcards({required String deckId}) async {
    final uid = _uid;

    final deckRef = await _requireOwnedDeck(deckId, uid);

    _requireSameUser(uid);

    final snapshot = await deckRef.collection('cards').get(_serverOnly);

    _requireSameUser(uid);

    final cards = snapshot.docs.map((document) {
      if (document.metadata.hasPendingWrites) {
        throw StateError('Flashcard changes are awaiting confirmation.');
      }

      return FirestoreStudyMapper.flashcardFromMap(
        id: document.id,
        deckId: deckId,
        data: document.data(),
      );
    }).toList();

    cards.sort((a, b) {
      final byDate = a.createdAt.compareTo(b.createdAt);

      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });

    return List<Flashcard>.unmodifiable(cards);
  }

  Future<void> createFlashcard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final uid = _uid;
    final cleanFront = _requiredText(front, 'Question');
    final cleanBack = _requiredText(back, 'Answer');

    final deckRef = await _requireOwnedDeck(deckId, uid);

    _requireSameUser(uid);

    await deckRef.collection('cards').add({
      'deckId': deckId,
      'front': cleanFront,
      'back': cleanBack,
      'sourceNoteId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFlashcard({
    required String deckId,
    required String cardId,
    required String front,
    required String back,
  }) async {
    final uid = _uid;

    final cleanFront = _requiredText(front, 'Question');
    final cleanBack = _requiredText(back, 'Answer');

    final deckRef = _deckRef(deckId);
    final cardRef = deckRef.collection('cards').doc(_documentId(cardId));

    final progressRef = _progressRef(uid: uid, deckId: deckId, cardId: cardId);

    await _db.runTransaction<void>((transaction) async {
      _requireSameUser(uid);

      final parent = await transaction.get(deckRef);
      final card = await transaction.get(cardRef);

      _requireSameUser(uid);

      if (!parent.exists ||
          parent.data()?['ownerId'] != uid ||
          parent.data()?['deleting'] == true) {
        throw StateError('Deck unavailable.');
      }

      if (!card.exists || card.data()?['deckId'] != deckId) {
        throw StateError('Flashcard not found.');
      }

      final previous = card.data()!;

      final changed =
          previous['front'] != cleanFront || previous['back'] != cleanBack;

      if (!changed) return;

      transaction.delete(progressRef);

      transaction.update(cardRef, {
        'front': cleanFront,
        'back': cleanBack,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteFlashcard({
    required String deckId,
    required String cardId,
  }) async {
    final uid = _uid;

    final deckRef = _deckRef(deckId);
    final cardRef = deckRef.collection('cards').doc(_documentId(cardId));

    final progressRef = _progressRef(uid: uid, deckId: deckId, cardId: cardId);

    await _db.runTransaction<void>((transaction) async {
      _requireSameUser(uid);

      final parent = await transaction.get(deckRef);
      final card = await transaction.get(cardRef);

      _requireSameUser(uid);

      if (!parent.exists ||
          parent.data()?['ownerId'] != uid ||
          parent.data()?['deleting'] == true) {
        throw StateError('Deck unavailable.');
      }

      if (!card.exists || card.data()?['deckId'] != deckId) {
        throw StateError('Flashcard not found.');
      }

      transaction.delete(progressRef);
      transaction.delete(cardRef);
    });
  }

  Future<List<StudyProgress>> fetchProgress({required String deckId}) async {
    final uid = _uid;

    await _requireOwnedDeck(deckId, uid);

    final snapshot = await _progressQuery(
      uid: uid,
      deckId: deckId,
    ).get(_serverOnly);

    _requireSameUser(uid);

    final records = <StudyProgress>[];

    for (final document in snapshot.docs) {
      if (document.metadata.hasPendingWrites) {
        throw StateError('Study results are awaiting confirmation.');
      }

      final progress = FirestoreStudyMapper.progressFromMap(
        expectedUserId: uid,
        expectedDeckId: deckId,
        data: document.data(),
      );

      final expectedId = StudyProgressKey.build(
        userId: uid,
        deckId: deckId,
        cardId: progress.cardId,
      );

      if (document.id != expectedId) {
        throw const FormatException('Invalid progress document identity.');
      }

      records.add(progress);
    }

    records.sort((a, b) => a.cardId.compareTo(b.cardId));

    return List<StudyProgress>.unmodifiable(records);
  }

  Future<void> saveSessionResults({
    required String deckId,
    required Map<String, StudyResult> results,
    Map<String, Flashcard>? expectedCards,
  }) async {
    final uid = _uid;

    if (results.isEmpty) {
      throw ArgumentError('Session results cannot be empty.');
    }

    if (results.length > maxSessionResults) {
      throw ArgumentError(
        'A session can save at most '
        '$maxSessionResults flashcard results.',
      );
    }

    final sessionResults = Map<String, StudyResult>.unmodifiable(results);

    final expected = expectedCards == null
        ? null
        : Map<String, Flashcard>.unmodifiable(expectedCards);

    if (expected != null && expected.length != sessionResults.length) {
      throw ArgumentError('Session snapshot mismatch.');
    }

    final deckRef = _deckRef(deckId);

    // Validate every identity before starting a write.
    final progressIds = <String, String>{};

    for (final cardId in sessionResults.keys) {
      _documentId(cardId);

      progressIds[cardId] = StudyProgressKey.build(
        userId: uid,
        deckId: deckId,
        cardId: cardId,
      );
    }

    await _db.runTransaction<void>((transaction) async {
      _requireSameUser(uid);

      final deckSnapshot = await transaction.get(deckRef);

      _requireSameUser(uid);

      if (!deckSnapshot.exists || deckSnapshot.data()?['ownerId'] != uid) {
        throw StateError('Deck not found or access denied.');
      }

      if (deckSnapshot.data()?['deleting'] == true) {
        throw StateError('This deck is being deleted.');
      }

      // All transaction reads happen before any writes.
      for (final cardId in sessionResults.keys) {
        final cardRef = deckRef.collection('cards').doc(cardId);

        final cardSnapshot = await transaction.get(cardRef);

        _requireSameUser(uid);

        if (!cardSnapshot.exists || cardSnapshot.data()?['deckId'] != deckId) {
          throw StateError(
            'A flashcard is missing or belongs '
            'to another deck.',
          );
        }

        if (expected != null) {
          final original = expected[cardId];
          final current = cardSnapshot.data()!;

          if (original == null ||
              original.id != cardId ||
              original.deckId != deckId ||
              original.front != current['front'] ||
              original.back != current['back']) {
            throw StateError('Flashcard content changed during study.');
          }
        }
      }

      _requireSameUser(uid);

      for (final entry in sessionResults.entries) {
        final progressRef = _db
            .collection('progress')
            .doc(progressIds[entry.key]!);

        transaction.set(progressRef, {
          'userId': uid,
          'deckId': deckId,
          'cardId': entry.key,

          'lastResult': FirestoreStudyMapper.encodeStudyResult(entry.value),

          'lastReviewedAt': FieldValue.serverTimestamp(),

          'nextReviewAt': null,
        });
      }
    });
  }

  Future<List<Flashcard>> fetchCardsNeedingReview({
    required String deckId,
  }) async {
    final uid = _uid;

    final progress = await fetchProgress(deckId: deckId);

    _requireSameUser(uid);

    final reviewIds = progress
        .where((item) => item.lastResult == StudyResult.stillLearning)
        .map((item) => item.cardId)
        .toSet();

    if (reviewIds.isEmpty) {
      return const <Flashcard>[];
    }

    final cards = await fetchFlashcards(deckId: deckId);

    _requireSameUser(uid);

    return List<Flashcard>.unmodifiable(
      cards.where((card) => reviewIds.contains(card.id)),
    );
  }
}
