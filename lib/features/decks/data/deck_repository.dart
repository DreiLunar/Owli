import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../flashcards/data/mappers/firestore_study_mapper.dart';
import '../../flashcards/domain/models/deck.dart';
import '../../flashcards/domain/models/flashcard.dart';

class DeckRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DeckRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const _serverOnly = GetOptions(source: Source.server);

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Authentication required.');
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

  Future<DocumentSnapshot<Map<String, dynamic>>> _requireCard(
    DocumentReference<Map<String, dynamic>> deckRef,
    String cardId,
    String uid,
  ) async {
    _requireSameUser(uid);

    final snapshot = await deckRef
        .collection('cards')
        .doc(_documentId(cardId))
        .get(_serverOnly);

    _requireSameUser(uid);

    if (!snapshot.exists || snapshot.data()?['deckId'] != deckRef.id) {
      throw StateError('Flashcard not found in this deck.');
    }

    return snapshot;
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

  // Keep destructive operations within one batch.
  void _validateBatchSize(int documentCount) {
    if (documentCount > 400) {
      throw StateError('Too many documents for this MVP operation.');
    }
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

    final deckRef = await _requireOwnedDeck(deckId, uid);

    final cards = await deckRef.collection('cards').get(_serverOnly);

    _requireSameUser(uid);

    final progress = await _progressQuery(
      uid: uid,
      deckId: deckId,
    ).get(_serverOnly);

    _requireSameUser(uid);

    final refs = [
      ...cards.docs.map((doc) => doc.reference),
      ...progress.docs.map((doc) => doc.reference),
      deckRef,
    ];

    _validateBatchSize(refs.length);

    final batch = _db.batch();

    for (final ref in refs) {
      batch.delete(ref);
    }

    await batch.commit();
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

    final deckRef = await _requireOwnedDeck(deckId, uid);

    final card = await _requireCard(deckRef, cardId, uid);

    final previous = card.data()!;

    final contentChanged =
        previous['front'] != cleanFront || previous['back'] != cleanBack;

    final batch = _db.batch();

    if (contentChanged) {
      final progress = await _progressQuery(
        uid: uid,
        deckId: deckId,
      ).where('cardId', isEqualTo: cardId).get(_serverOnly);

      _requireSameUser(uid);
      _validateBatchSize(progress.docs.length + 1);

      for (final document in progress.docs) {
        batch.delete(document.reference);
      }
    }

    _requireSameUser(uid);

    batch.update(card.reference, {
      'front': cleanFront,
      'back': cleanBack,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deleteFlashcard({
    required String deckId,
    required String cardId,
  }) async {
    final uid = _uid;

    final deckRef = await _requireOwnedDeck(deckId, uid);

    final card = await _requireCard(deckRef, cardId, uid);

    final progress = await _progressQuery(
      uid: uid,
      deckId: deckId,
    ).where('cardId', isEqualTo: cardId).get(_serverOnly);

    _requireSameUser(uid);
    _validateBatchSize(progress.docs.length + 1);

    final batch = _db.batch();

    for (final document in progress.docs) {
      batch.delete(document.reference);
    }

    batch.delete(card.reference);

    await batch.commit();
  }
}
