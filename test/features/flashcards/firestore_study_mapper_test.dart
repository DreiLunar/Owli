import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mappers/firestore_study_mapper.dart';
import 'package:owli/features/flashcards/domain/models/study_progress.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 24);
  final updatedAt = DateTime.utc(2026, 11, 26);
  final reviewedAt = DateTime.utc(2026, 11, 26, 12);
  final nextReviewAt = DateTime.utc(2026, 11, 27);

  Map<String, dynamic> deckData() => {
    'ownerId': 'user_001',
    'subjectId': 'subject_001',
    'title': 'Automata Theory',
    'description': 'Finite automata',
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> cardData() => {
    'deckId': 'deck_001',
    'front': 'What is a DFA?',
    'back': 'A deterministic finite automaton.',
    'sourceNoteId': 'note_001',
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> progressData() => {
    'userId': 'user_001',
    'deckId': 'deck_001',
    'cardId': 'card_001',
    'lastResult': 'gotIt',
    'lastReviewedAt': Timestamp.fromDate(reviewedAt),
    'nextReviewAt': Timestamp.fromDate(nextReviewAt),
  };

  group('Deck Mapping', () {
    // TEST 1
    test('Maps a valid Firestore deck', () {
      final deck = FirestoreStudyMapper.deckFromMap(
        id: 'deck_001',
        data: deckData(),
      );

      expect(deck.id, 'deck_001');
      expect(deck.ownerId, 'user_001');
      expect(deck.subjectId, 'subject_001');
      expect(deck.title, 'Automata Theory');
      expect(deck.description, 'Finite automata');
      expect(deck.createdAt, createdAt);
      expect(deck.updatedAt, updatedAt);
      expect(deck.createdAt.isUtc, isTrue);
    });

    // TEST 2
    test('Handles missing optional deck fields', () {
      final data = deckData()
        ..remove('subjectId')
        ..remove('description');

      final deck = FirestoreStudyMapper.deckFromMap(id: 'deck_001', data: data);

      expect(deck.subjectId, isNull);
      expect(deck.description, isEmpty);
    });

    // TEST 3
    test('Rejects invalid required deck fields', () {
      for (final field in ['ownerId', 'title']) {
        for (final invalid in [null, 123, '', '   ']) {
          final data = deckData();
          data[field] = invalid;

          expect(
            () => FirestoreStudyMapper.deckFromMap(id: 'deck_001', data: data),
            throwsFormatException,
          );
        }
      }

      expect(
        () => FirestoreStudyMapper.deckFromMap(id: '', data: deckData()),
        throwsFormatException,
      );
    });

    // TEST 4
    test('Rejects malformed optional deck fields', () {
      for (final field in ['description', 'subjectId']) {
        final data = deckData();
        data[field] = 123;

        expect(
          () => FirestoreStudyMapper.deckFromMap(id: 'deck_001', data: data),
          throwsFormatException,
        );
      }
    });

    // TEST 5
    test('Rejects invalid or unresolved timestamps', () {
      for (final field in ['createdAt', 'updatedAt']) {
        for (final invalid in [null, '2026-11-24', 123]) {
          final data = deckData();
          data[field] = invalid;

          expect(
            () => FirestoreStudyMapper.deckFromMap(id: 'deck_001', data: data),
            throwsFormatException,
          );
        }

        final missingData = deckData()..remove(field);

        expect(
          () => FirestoreStudyMapper.deckFromMap(
            id: 'deck_001',
            data: missingData,
          ),
          throwsFormatException,
        );
      }
    });

    // TEST 6
    test('Deck round-trip preserves document fields', () {
      final original = deckData();

      final deck = FirestoreStudyMapper.deckFromMap(
        id: 'deck_001',
        data: original,
      );

      final serialized = FirestoreStudyMapper.deckToMap(deck);

      expect(serialized, equals(original));
      expect(serialized.containsKey('id'), isFalse);
      expect(serialized['createdAt'], isA<Timestamp>());
    });
  });

  group('Flashcard Mapping', () {
    // TEST 7
    test('Maps a valid Firestore flashcard', () {
      final card = FirestoreStudyMapper.flashcardFromMap(
        id: 'card_001',
        deckId: 'deck_001',
        data: cardData(),
      );

      expect(card.id, 'card_001');
      expect(card.deckId, 'deck_001');
      expect(card.front, 'What is a DFA?');

      expect(card.back, 'A deterministic finite automaton.');

      expect(card.sourceNoteId, 'note_001');
      expect(card.createdAt, createdAt);
      expect(card.updatedAt, updatedAt);
    });

    // TEST 8
    test('Handles a missing or null source note', () {
      final missing = cardData()..remove('sourceNoteId');

      final explicitNull = cardData()..['sourceNoteId'] = null;

      for (final data in [missing, explicitNull]) {
        final card = FirestoreStudyMapper.flashcardFromMap(
          id: 'card_001',
          deckId: 'deck_001',
          data: data,
        );

        expect(card.sourceNoteId, isNull);
      }
    });

    // TEST 9
    test('Rejects mismatched parent deck ID', () {
      expect(
        () => FirestoreStudyMapper.flashcardFromMap(
          id: 'card_001',
          deckId: 'another_deck',
          data: cardData(),
        ),
        throwsFormatException,
      );
    });

    // TEST 10
    test('Rejects malformed flashcard fields', () {
      for (final field in [
        'deckId',
        'front',
        'back',
        'createdAt',
        'updatedAt',
      ]) {
        final data = cardData()..remove(field);

        expect(
          () => FirestoreStudyMapper.flashcardFromMap(
            id: 'card_001',
            deckId: 'deck_001',
            data: data,
          ),
          throwsFormatException,
        );
      }

      final invalidFront = cardData()..['front'] = '   ';

      expect(
        () => FirestoreStudyMapper.flashcardFromMap(
          id: 'card_001',
          deckId: 'deck_001',
          data: invalidFront,
        ),
        throwsFormatException,
      );
    });

    // TEST 11
    test('Flashcard round-trip preserves fields', () {
      final original = cardData();

      final card = FirestoreStudyMapper.flashcardFromMap(
        id: 'card_001',
        deckId: 'deck_001',
        data: original,
      );

      final serialized = FirestoreStudyMapper.flashcardToMap(card);

      expect(serialized, equals(original));
      expect(serialized.containsKey('id'), isFalse);
    });
  });

  group('Study Progress Mapping', () {
    // TEST 12
    test('Maps a valid progress record', () {
      final progress = FirestoreStudyMapper.progressFromMap(
        expectedUserId: 'user_001',
        expectedDeckId: 'deck_001',
        data: progressData(),
      );

      expect(progress.userId, 'user_001');
      expect(progress.deckId, 'deck_001');
      expect(progress.cardId, 'card_001');
      expect(progress.lastResult, StudyResult.gotIt);
      expect(progress.lastReviewedAt, reviewedAt);
      expect(progress.nextReviewAt, nextReviewAt);
    });

    // TEST 13
    test('Handles optional next review timestamp', () {
      final missing = progressData()..remove('nextReviewAt');

      final explicitNull = progressData()..['nextReviewAt'] = null;

      for (final data in [missing, explicitNull]) {
        final progress = FirestoreStudyMapper.progressFromMap(
          expectedUserId: 'user_001',
          expectedDeckId: 'deck_001',
          data: data,
        );

        expect(progress.nextReviewAt, isNull);

        expect(
          FirestoreStudyMapper.progressToMap(progress)['nextReviewAt'],
          isNull,
        );
      }
    });

    // TEST 14
    test('Rejects mismatched progress user or deck', () {
      expect(
        () => FirestoreStudyMapper.progressFromMap(
          expectedUserId: 'another_user',
          expectedDeckId: 'deck_001',
          data: progressData(),
        ),
        throwsFormatException,
      );

      expect(
        () => FirestoreStudyMapper.progressFromMap(
          expectedUserId: 'user_001',
          expectedDeckId: 'another_deck',
          data: progressData(),
        ),
        throwsFormatException,
      );
    });

    // TEST 15
    test('Rejects malformed progress fields', () {
      for (final field in [
        'userId',
        'deckId',
        'cardId',
        'lastResult',
        'lastReviewedAt',
      ]) {
        final data = progressData()..remove(field);

        expect(
          () => FirestoreStudyMapper.progressFromMap(
            expectedUserId: 'user_001',
            expectedDeckId: 'deck_001',
            data: data,
          ),
          throwsFormatException,
        );
      }

      final invalidDate = progressData()..['nextReviewAt'] = 'tomorrow';

      expect(
        () => FirestoreStudyMapper.progressFromMap(
          expectedUserId: 'user_001',
          expectedDeckId: 'deck_001',
          data: invalidDate,
        ),
        throwsFormatException,
      );
    });

    // TEST 16
    test('Progress round-trip preserves both outcomes', () {
      for (final result in ['gotIt', 'stillLearning']) {
        final original = progressData()..['lastResult'] = result;

        final progress = FirestoreStudyMapper.progressFromMap(
          expectedUserId: 'user_001',
          expectedDeckId: 'deck_001',
          data: original,
        );

        final serialized = FirestoreStudyMapper.progressToMap(progress);

        expect(serialized, equals(original));
      }
    });
  });

  group('Study Result Serialization', () {
    // TEST 17
    test('Converts both study outcomes correctly', () {
      expect(
        FirestoreStudyMapper.encodeStudyResult(StudyResult.gotIt),
        'gotIt',
      );

      expect(
        FirestoreStudyMapper.encodeStudyResult(StudyResult.stillLearning),
        'stillLearning',
      );

      expect(
        FirestoreStudyMapper.decodeStudyResult('gotIt'),
        StudyResult.gotIt,
      );

      expect(
        FirestoreStudyMapper.decodeStudyResult('stillLearning'),
        StudyResult.stillLearning,
      );
    });

    // TEST 18
    test('Rejects unknown study result values', () {
      for (final invalid in [null, 0, 1, true, '', 'Got It', 'unknown']) {
        expect(
          () => FirestoreStudyMapper.decodeStudyResult(invalid),
          throwsFormatException,
        );
      }
    });
  });
}
