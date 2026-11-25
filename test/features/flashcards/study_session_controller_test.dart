import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/domain/models/flashcard.dart';
import 'package:owli/features/flashcards/domain/models/study_progress.dart';
import 'package:owli/features/flashcards/domain/services/study_session_controller.dart';

void main() {
  late MockStudyStore store;
  late StudySessionController session;

  setUp(() {
    store = MockStudyStore();

    session = StudySessionController(
      deckId: 'deck_001',
      cards: store.cardsForDeck('deck_001'),
    );
  });

  // Helper for rating the current card.
  void rateCard(StudyResult result) {
    final card = session.currentCard!;

    if (!session.isAnswerVisible) {
      session.toggleAnswer();
    }

    session.rateCurrentCard(cardId: card.id, result: result);
  }

  group('Session Initialization', () {
    test('Initialize a valid study session', () {
      expect(session.totalCards, 2);
      expect(session.reviewedCards, 0);
      expect(session.remainingCards, 2);
      expect(session.currentCardNumber, 1);
      expect(session.isCompleted, isFalse);
      expect(session.isAnswerVisible, isFalse);
      expect(session.progress, 0.0);
      expect(session.recallPercentage, 0.0);
    });

    test('Reject an empty flashcard list', () {
      expect(
        () => StudySessionController(deckId: 'deck_001', cards: []),
        throwsArgumentError,
      );
    });

    test('Reject cards belonging to another deck', () {
      expect(
        () => StudySessionController(
          deckId: 'deck_001',
          cards: store.cardsForDeck('deck_002'),
        ),
        throwsArgumentError,
      );
    });

    test('Reject duplicate flashcard IDs', () {
      final card = store.cardsForDeck('deck_001').first;

      expect(
        () => StudySessionController(deckId: 'deck_001', cards: [card, card]),
        throwsArgumentError,
      );
    });

    test('Session preserves its original card list', () {
      final cards = List<Flashcard>.of(store.cardsForDeck('deck_001'));

      final newSession = StudySessionController(
        deckId: 'deck_001',
        cards: cards,
      );

      cards.clear();

      expect(newSession.totalCards, 2);
    });
  });

  group('Answer Visibility', () {
    test('Display the first question', () {
      expect(session.currentCard!.front, 'What is a DFA?');

      expect(session.isAnswerVisible, isFalse);
    });

    test('Reveal and hide the answer', () {
      session.toggleAnswer();

      expect(session.isAnswerVisible, isTrue);

      session.toggleAnswer();

      expect(session.isAnswerVisible, isFalse);
    });

    test('Reject rating before revealing the answer', () {
      expect(
        () => session.rateCurrentCard(
          cardId: session.currentCard!.id,
          result: StudyResult.gotIt,
        ),
        throwsStateError,
      );

      expect(session.reviewedCards, 0);
    });
  });

  group('Flashcard Rating', () {
    test('Record Got It and advance to next card', () {
      rateCard(StudyResult.gotIt);

      expect(session.gotItCount, 1);
      expect(session.stillLearningCount, 0);
      expect(session.reviewedCards, 1);
      expect(session.currentCardNumber, 2);

      expect(session.currentCard!.id, 'card_002');

      expect(session.isAnswerVisible, isFalse);
    });

    test('Record Still Learning', () {
      rateCard(StudyResult.stillLearning);

      expect(session.gotItCount, 0);
      expect(session.stillLearningCount, 1);

      expect(session.stillLearningCards.single.id, 'card_001');
    });

    test('Reject rating the wrong flashcard', () {
      session.toggleAnswer();

      expect(
        () => session.rateCurrentCard(
          cardId: 'invalid_card',
          result: StudyResult.gotIt,
        ),
        throwsStateError,
      );

      expect(session.reviewedCards, 0);
    });

    test('Reject a duplicate rating of a previous card', () {
      final firstCardId = session.currentCard!.id;

      rateCard(StudyResult.gotIt);

      session.toggleAnswer();

      expect(
        () => session.rateCurrentCard(
          cardId: firstCardId,
          result: StudyResult.gotIt,
        ),
        throwsStateError,
      );

      expect(session.reviewedCards, 1);
    });

    test('Results cannot be modified externally', () {
      rateCard(StudyResult.gotIt);

      expect(() {
        session.results.clear();
      }, throwsUnsupportedError);

      expect(session.reviewedCards, 1);
    });
  });

  group('Session Progress and Completion', () {
    test('Calculate progress after reviewing one card', () {
      rateCard(StudyResult.gotIt);

      expect(session.progress, 0.5);
      expect(session.completionPercentage, 50.0);
      expect(session.recallPercentage, 100.0);
      expect(session.remainingCards, 1);
      expect(session.isCompleted, isFalse);
    });

    test('Complete a session with mixed outcomes', () {
      rateCard(StudyResult.gotIt);
      rateCard(StudyResult.stillLearning);

      expect(session.isCompleted, isTrue);
      expect(session.reviewedCards, 2);
      expect(session.remainingCards, 0);
      expect(session.gotItCount, 1);
      expect(session.stillLearningCount, 1);
      expect(session.progress, 1.0);
      expect(session.completionPercentage, 100.0);
      expect(session.recallPercentage, 50.0);
      expect(session.currentCard, isNull);
      expect(session.currentCardNumber, isNull);
      expect(session.isAnswerVisible, isFalse);
    });

    test('Reject rating after session completion', () {
      rateCard(StudyResult.gotIt);
      rateCard(StudyResult.gotIt);

      expect(
        () => session.rateCurrentCard(
          cardId: 'card_002',
          result: StudyResult.gotIt,
        ),
        throwsStateError,
      );

      expect(session.reviewedCards, 2);
    });

    test('Reject revealing after session completion', () {
      rateCard(StudyResult.gotIt);
      rateCard(StudyResult.gotIt);

      expect(() => session.toggleAnswer(), throwsStateError);
    });

    test('Complete a single-card session', () {
      session = StudySessionController(
        deckId: 'deck_001',
        cards: [store.cardsForDeck('deck_001').first],
      );

      rateCard(StudyResult.gotIt);

      expect(session.isCompleted, isTrue);
      expect(session.totalCards, 1);
      expect(session.recallPercentage, 100.0);
    });

    test('Restart a completed session', () {
      rateCard(StudyResult.gotIt);
      rateCard(StudyResult.stillLearning);

      session.restart();

      expect(session.isCompleted, isFalse);
      expect(session.currentCardNumber, 1);
      expect(session.reviewedCards, 0);
      expect(session.remainingCards, 2);
      expect(session.gotItCount, 0);
      expect(session.stillLearningCount, 0);
      expect(session.progress, 0.0);
      expect(session.results, isEmpty);
      expect(session.isAnswerVisible, isFalse);
    });

    test('Restart an incomplete session', () {
      rateCard(StudyResult.stillLearning);

      session.toggleAnswer();

      session.restart();

      expect(session.currentCardNumber, 1);
      expect(session.reviewedCards, 0);
      expect(session.isAnswerVisible, isFalse);
    });
  });
}
