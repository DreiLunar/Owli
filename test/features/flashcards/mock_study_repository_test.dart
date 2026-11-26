import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/data/repositories/mock_study_repository.dart';
import 'package:owli/features/flashcards/domain/models/study_progress.dart';
import 'package:owli/features/flashcards/domain/repositories/study_repository.dart';

void main() {
  late MockStudyStore store;
  late StudyRepository repository;

  setUp(() {
    store = MockStudyStore();

    repository = MockStudyRepository(store: store, userId: 'mock_user');
  });

  group('Repository Initialization', () {
    // TEST 1
    test('Implements the StudyRepository contract', () async {
      expect(repository, isA<StudyRepository>());
      expect(repository.userId, 'mock_user');

      final decks = await repository.fetchDecks();

      expect(decks.length, 3);
      expect(decks.every((deck) => deck.ownerId == repository.userId), isTrue);
    });

    // TEST 2
    test('Rejects an empty user ID', () {
      expect(
        () => MockStudyRepository(store: store, userId: '   '),
        throwsArgumentError,
      );
    });
  });

  group('Repository Deck Management', () {
    // TEST 3
    test('Creates a deck with owner and subject IDs', () async {
      await repository.createDeck(
        subjectId: 'subject_001',
        title: 'Web Systems',
        description: 'HTML and CSS',
      );

      final decks = await repository.fetchDecks();

      final created = decks.singleWhere((deck) => deck.title == 'Web Systems');

      expect(decks.length, 4);
      expect(created.ownerId, 'mock_user');
      expect(created.subjectId, 'subject_001');
      expect(created.description, 'HTML and CSS');
    });

    // TEST 4
    test('Updates a deck while preserving ownership', () async {
      await repository.createDeck(
        subjectId: 'subject_001',
        title: 'Original Title',
      );

      final before = (await repository.fetchDecks()).singleWhere(
        (deck) => deck.title == 'Original Title',
      );

      await repository.updateDeck(
        deckId: before.id,
        title: 'Updated Title',
        description: 'Updated description',
      );

      final after = (await repository.fetchDecks()).singleWhere(
        (deck) => deck.id == before.id,
      );

      expect(after.title, 'Updated Title');
      expect(after.description, 'Updated description');
      expect(after.ownerId, before.ownerId);
      expect(after.subjectId, before.subjectId);
      expect(after.createdAt, before.createdAt);
    });

    // TEST 5
    test('Deleting a deck removes cards and progress', () async {
      await repository.saveSessionResults(
        deckId: 'deck_001',
        results: {'card_001': StudyResult.gotIt},
      );

      await repository.deleteDeck('deck_001');

      final decks = await repository.fetchDecks();

      expect(decks.any((deck) => deck.id == 'deck_001'), isFalse);

      expect(store.cardsForDeck('deck_001'), isEmpty);

      expect(
        store.progressForDeck(userId: 'mock_user', deckId: 'deck_001'),
        isEmpty,
      );

      expect(
        await repository.fetchFlashcards(deckId: 'deck_002'),
        hasLength(2),
      );
    });
  });

  group('Repository Flashcard Management', () {
    // TEST 6
    test('Creates and retrieves flashcards', () async {
      await repository.createFlashcard(
        deckId: 'deck_001',
        front: 'New question',
        back: 'New answer',
      );

      final cards = await repository.fetchFlashcards(deckId: 'deck_001');

      expect(cards.length, 3);

      final created = cards.singleWhere((card) => card.front == 'New question');

      expect(created.back, 'New answer');
      expect(created.deckId, 'deck_001');
    });

    // TEST 7
    test('Updating card content invalidates progress', () async {
      await repository.saveSessionResults(
        deckId: 'deck_001',
        results: {'card_001': StudyResult.gotIt},
      );

      await repository.updateFlashcard(
        deckId: 'deck_001',
        cardId: 'card_001',
        front: 'Updated question',
        back: 'Updated answer',
      );

      final cards = await repository.fetchFlashcards(deckId: 'deck_001');

      final updated = cards.singleWhere((card) => card.id == 'card_001');

      expect(updated.front, 'Updated question');
      expect(updated.back, 'Updated answer');

      expect(await repository.fetchProgress(deckId: 'deck_001'), isEmpty);
    });

    // TEST 8
    test('Deleting a flashcard removes its progress', () async {
      await repository.saveSessionResults(
        deckId: 'deck_001',
        results: {
          'card_001': StudyResult.gotIt,
          'card_002': StudyResult.stillLearning,
        },
      );

      await repository.deleteFlashcard(deckId: 'deck_001', cardId: 'card_001');

      final cards = await repository.fetchFlashcards(deckId: 'deck_001');

      final progress = await repository.fetchProgress(deckId: 'deck_001');

      expect(cards.length, 1);
      expect(cards.single.id, 'card_002');

      expect(progress.length, 1);
      expect(progress.single.cardId, 'card_002');
    });
  });

  group('Repository Study Progress', () {
    // TEST 9
    test('Saves and updates latest study outcomes', () async {
      await repository.saveSessionResults(
        deckId: 'deck_001',
        results: {
          'card_001': StudyResult.gotIt,
          'card_002': StudyResult.stillLearning,
        },
      );

      var progress = await repository.fetchProgress(deckId: 'deck_001');

      expect(progress.length, 2);

      final reviewCards = await repository.fetchCardsNeedingReview(
        deckId: 'deck_001',
      );

      expect(reviewCards.length, 1);
      expect(reviewCards.single.id, 'card_002');

      await repository.saveSessionResults(
        deckId: 'deck_001',
        results: {'card_002': StudyResult.gotIt},
      );

      progress = await repository.fetchProgress(deckId: 'deck_001');

      expect(progress.length, 2);

      expect(
        progress.every((item) => item.lastResult == StudyResult.gotIt),
        isTrue,
      );

      expect(
        progress.every((item) => item.userId == repository.userId),
        isTrue,
      );

      expect(
        await repository.fetchCardsNeedingReview(deckId: 'deck_001'),
        isEmpty,
      );
    });
  });

  group('Repository User Isolation', () {
    // TEST 10
    test('Different users only see their own decks', () async {
      final otherRepository = MockStudyRepository(
        store: store,
        userId: 'user_b',
      );

      expect(await otherRepository.fetchDecks(), isEmpty);

      await otherRepository.createDeck(
        subjectId: 'subject_b',
        title: 'Private Deck',
      );

      final otherDecks = await otherRepository.fetchDecks();

      expect(otherDecks.length, 1);
      expect(otherDecks.single.ownerId, 'user_b');

      final originalDecks = await repository.fetchDecks();

      expect(originalDecks.length, 3);

      expect(
        originalDecks.any((deck) => deck.title == 'Private Deck'),
        isFalse,
      );
    });

    // TEST 11
    test('Rejects unauthorized deck operations', () async {
      final otherRepository = MockStudyRepository(
        store: store,
        userId: 'user_b',
      );

      await expectLater(
        otherRepository.updateDeck(
          deckId: 'deck_001',
          title: 'Unauthorized update',
        ),
        throwsStateError,
      );

      await expectLater(
        otherRepository.deleteDeck('deck_001'),
        throwsStateError,
      );

      await expectLater(
        otherRepository.fetchFlashcards(deckId: 'deck_001'),
        throwsStateError,
      );

      await expectLater(
        otherRepository.createFlashcard(
          deckId: 'deck_001',
          front: 'Unauthorized question',
          back: 'Unauthorized answer',
        ),
        throwsStateError,
      );

      await expectLater(
        otherRepository.updateFlashcard(
          deckId: 'deck_001',
          cardId: 'card_001',
          front: 'Unauthorized question',
          back: 'Unauthorized answer',
        ),
        throwsStateError,
      );

      await expectLater(
        otherRepository.deleteFlashcard(deckId: 'deck_001', cardId: 'card_001'),
        throwsStateError,
      );

      await expectLater(
        otherRepository.fetchProgress(deckId: 'deck_001'),
        throwsStateError,
      );

      await expectLater(
        otherRepository.saveSessionResults(
          deckId: 'deck_001',
          results: {'card_001': StudyResult.gotIt},
        ),
        throwsStateError,
      );

      await expectLater(
        otherRepository.fetchCardsNeedingReview(deckId: 'deck_001'),
        throwsStateError,
      );

      expect(await repository.fetchDecks(), hasLength(3));

      expect(
        await repository.fetchFlashcards(deckId: 'deck_001'),
        hasLength(2),
      );

      expect(await repository.fetchProgress(deckId: 'deck_001'), isEmpty);
    });
  });

  group('Repository Validation', () {
    // TEST 12
    test('Rejects invalid data without partial changes', () async {
      await expectLater(
        repository.createDeck(subjectId: '   ', title: 'Invalid Subject'),
        throwsArgumentError,
      );

      await expectLater(
        repository.createDeck(subjectId: 'subject_001', title: '   '),
        throwsArgumentError,
      );

      await expectLater(
        repository.createFlashcard(
          deckId: 'deck_001',
          front: '   ',
          back: 'Answer',
        ),
        throwsArgumentError,
      );

      await expectLater(
        repository.fetchFlashcards(deckId: 'missing_deck'),
        throwsStateError,
      );

      await expectLater(
        repository.saveSessionResults(
          deckId: 'deck_001',
          results: {
            'card_001': StudyResult.gotIt,
            'card_003': StudyResult.stillLearning,
          },
        ),
        throwsStateError,
      );

      expect(await repository.fetchDecks(), hasLength(3));

      expect(
        await repository.fetchFlashcards(deckId: 'deck_001'),
        hasLength(2),
      );

      expect(await repository.fetchProgress(deckId: 'deck_001'), isEmpty);
    });

    test('Rejects stale study snapshots atomically', () async {
      final cards = await repository.fetchFlashcards(deckId: 'deck_001');

      final original = {for (final card in cards) card.id: card};

      await repository.updateFlashcard(
        deckId: 'deck_001',
        cardId: 'card_001',
        front: 'Updated question',
        back: 'Updated answer',
      );

      await expectLater(
        repository.saveSessionResults(
          deckId: 'deck_001',
          results: {
            'card_001': StudyResult.gotIt,
            'card_002': StudyResult.gotIt,
          },
          expectedCards: original,
        ),
        throwsStateError,
      );

      expect(await repository.fetchProgress(deckId: 'deck_001'), isEmpty);
    });

    test('Accepts unchanged study snapshots', () async {
      final cards = await repository.fetchFlashcards(deckId: 'deck_001');

      await repository.saveSessionResults(
        deckId: 'deck_001',
        results: {for (final card in cards) card.id: StudyResult.gotIt},
        expectedCards: {for (final card in cards) card.id: card},
      );

      expect(await repository.fetchProgress(deckId: 'deck_001'), hasLength(2));
    });
  });
}
