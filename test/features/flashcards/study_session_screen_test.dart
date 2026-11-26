import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/domain/services/study_session_controller.dart';
import 'package:owli/features/flashcards/domain/models/study_progress.dart';
import 'package:owli/features/flashcards/presentation/screens/deck_details_screen.dart';
import 'package:owli/features/flashcards/presentation/screens/study_session_screen.dart';

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

  // CONFIGURE TEST VIEWPORT
  Future<void> configureViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() {
      return tester.binding.setSurfaceSize(null);
    });
  }

  // PUMP STUDY SESSION SCREEN
  Future<void> pumpStudyScreen(WidgetTester tester) async {
    await configureViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionScreen(
          deckTitle: 'Automata Theory',
          session: session,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  // TAP A CONTROL BY KEY
  Future<void> tapControl(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));

    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
    }

    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // MILESTONE 3.2 — INTERACTIVE FLASHCARD FLIP
  group('Study Session Screen', () {
    testWidgets('Initially displays question and hides answer', (tester) async {
      await pumpStudyScreen(tester);

      expect(find.text('What is a DFA?'), findsOneWidget);

      expect(find.text('A deterministic finite automaton.'), findsNothing);

      expect(find.text('Card 1 of 2'), findsOneWidget);

      expect(session.isAnswerVisible, isFalse);
    });

    testWidgets('Tapping card reveals and hides answer', (tester) async {
      await pumpStudyScreen(tester);

      final flashcard = find.byKey(const ValueKey('study_flashcard'));

      await tester.tap(flashcard);
      await tester.pumpAndSettle();

      expect(session.isAnswerVisible, isTrue);

      expect(find.text('A deterministic finite automaton.'), findsOneWidget);

      expect(find.text('What is a DFA?'), findsNothing);

      await tester.tap(flashcard);
      await tester.pumpAndSettle();

      expect(session.isAnswerVisible, isFalse);

      expect(find.text('What is a DFA?'), findsOneWidget);
    });

    testWidgets('Show Answer and Hide Answer button works', (tester) async {
      await pumpStudyScreen(tester);

      final button = find.byKey(const ValueKey('toggle_answer_button'));

      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(session.isAnswerVisible, isTrue);

      expect(find.text('Hide Answer'), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(session.isAnswerVisible, isFalse);

      expect(find.text('Show Answer'), findsOneWidget);
    });

    testWidgets('Revealing an answer does not change progress', (tester) async {
      await pumpStudyScreen(tester);

      await tester.tap(find.byKey(const ValueKey('study_flashcard')));

      await tester.pumpAndSettle();

      expect(session.reviewedCards, 0);
      expect(session.remainingCards, 2);
      expect(session.progress, 0.0);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(indicator.value, 0.0);
    });

    testWidgets('Start study opens a fresh session', (tester) async {
      await configureViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: DeckDetailsScreen(deck: store.decks.first, store: store),
        ),
      );

      await tester.pumpAndSettle();

      await tapControl(tester, 'start_study_button');

      expect(find.byType(StudySessionScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('study_flashcard')));

      await tester.pumpAndSettle();

      expect(find.text('ANSWER'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(DeckDetailsScreen), findsOneWidget);

      await tapControl(tester, 'start_study_button');

      expect(find.text('QUESTION'), findsOneWidget);

      expect(find.text('Card 1 of 2'), findsOneWidget);
    });

    testWidgets('Start study is disabled for an empty deck', (tester) async {
      await configureViewport(tester);

      final emptyDeck = store.createDeck(title: 'Empty Deck');

      await tester.pumpWidget(
        MaterialApp(
          home: DeckDetailsScreen(deck: emptyDeck, store: store),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('start_study_button')),
      );

      expect(button.onPressed, isNull);

      expect(
        find.text('Add at least one flashcard to start studying.'),
        findsOneWidget,
      );
    });
  });

  // MILESTONE 3.3 — STUDY SESSION RATING
  group('Study Session Rating', () {
    final gotItButton = find.byKey(const ValueKey('got_it_button'));

    final stillLearningButton = find.byKey(
      const ValueKey('still_learning_button'),
    );

    // TEST 1
    testWidgets('Ratings are disabled until the answer is visible', (
      tester,
    ) async {
      await pumpStudyScreen(tester);

      expect(tester.widget<FilledButton>(gotItButton).onPressed, isNull);

      expect(
        tester.widget<OutlinedButton>(stillLearningButton).onPressed,
        isNull,
      );

      await tapControl(tester, 'toggle_answer_button');

      expect(tester.widget<FilledButton>(gotItButton).onPressed, isNotNull);

      expect(
        tester.widget<OutlinedButton>(stillLearningButton).onPressed,
        isNotNull,
      );

      await tapControl(tester, 'toggle_answer_button');

      expect(tester.widget<FilledButton>(gotItButton).onPressed, isNull);

      expect(
        tester.widget<OutlinedButton>(stillLearningButton).onPressed,
        isNull,
      );
    });

    // TEST 2
    testWidgets('Got It records outcome and advances the card', (tester) async {
      await pumpStudyScreen(tester);

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'got_it_button');

      expect(session.gotItCount, 1);
      expect(session.reviewedCards, 1);
      expect(session.currentCardNumber, 2);
      expect(session.isAnswerVisible, isFalse);

      expect(find.text('What is an alphabet?'), findsOneWidget);

      expect(find.text('Card 2 of 2'), findsOneWidget);

      expect(find.text('50% completed'), findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(indicator.value, 0.5);
    });

    // TEST 3
    testWidgets('Still Learning records outcome and advances', (tester) async {
      await pumpStudyScreen(tester);

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'still_learning_button');

      expect(session.stillLearningCount, 1);
      expect(session.gotItCount, 0);
      expect(session.reviewedCards, 1);
      expect(session.currentCardNumber, 2);

      expect(session.results['card_001'], StudyResult.stillLearning);

      expect(session.isAnswerVisible, isFalse);
    });

    // TEST 4
    testWidgets('Duplicate button callbacks cannot rate another card', (
      tester,
    ) async {
      await pumpStudyScreen(tester);

      await tapControl(tester, 'toggle_answer_button');

      final callback = tester.widget<FilledButton>(gotItButton).onPressed!;

      // Simulate two rapid submissions.
      callback();
      callback();

      await tester.pumpAndSettle();

      expect(session.reviewedCards, 1);
      expect(session.gotItCount, 1);
      expect(session.currentCardNumber, 2);
      expect(session.isAnswerVisible, isFalse);

      expect(tester.takeException(), isNull);
    });

    // TEST 5
    testWidgets('Complete a session with mixed ratings', (tester) async {
      await pumpStudyScreen(tester);

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'got_it_button');

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'still_learning_button');

      expect(session.isCompleted, isTrue);
      expect(session.reviewedCards, 2);
      expect(session.gotItCount, 1);
      expect(session.stillLearningCount, 1);
      expect(session.recallPercentage, 50.0);
      expect(session.progress, 1.0);

      expect(find.text('Session completed!'), findsOneWidget);

      expect(find.text('100% completed'), findsOneWidget);

      expect(gotItButton, findsNothing);
      expect(stillLearningButton, findsNothing);
    });

    // TEST 6
    testWidgets('Study Again resets the completed session', (tester) async {
      await pumpStudyScreen(tester);

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'got_it_button');

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'still_learning_button');

      await tapControl(tester, 'study_again_button');

      expect(session.isCompleted, isFalse);
      expect(session.currentCardNumber, 1);
      expect(session.reviewedCards, 0);
      expect(session.gotItCount, 0);
      expect(session.stillLearningCount, 0);
      expect(session.isAnswerVisible, isFalse);

      expect(find.text('What is a DFA?'), findsOneWidget);

      expect(find.text('0% completed'), findsOneWidget);
    });

    // TEST 7
    testWidgets('Complete a single-card study session', (tester) async {
      session = StudySessionController(
        deckId: 'deck_001',
        cards: [store.cardsForDeck('deck_001').first],
      );

      await pumpStudyScreen(tester);

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'got_it_button');

      expect(session.isCompleted, isTrue);
      expect(session.reviewedCards, 1);
      expect(session.recallPercentage, 100.0);

      expect(find.text('Session completed!'), findsOneWidget);
    });

    // TEST 8
    testWidgets('Done returns the user to Deck Details', (tester) async {
      await configureViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: DeckDetailsScreen(deck: store.decks.first, store: store),
        ),
      );

      await tester.pumpAndSettle();

      await tapControl(tester, 'start_study_button');

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'got_it_button');

      await tapControl(tester, 'toggle_answer_button');

      await tapControl(tester, 'still_learning_button');

      await tapControl(tester, 'finish_study_button');

      expect(find.byType(DeckDetailsScreen), findsOneWidget);

      expect(find.byType(StudySessionScreen), findsNothing);

      expect(store.cardCountForDeck('deck_001'), 2);
    });
  });

  group('Study Progress Integration', () {
    Future<void> openDeck(WidgetTester tester) async {
      await configureViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: DeckDetailsScreen(deck: store.decks.first, store: store),
        ),
      );

      await tester.pumpAndSettle();
    }

    Future<void> completeMixedSession(WidgetTester tester) async {
      await tapControl(tester, 'start_study_button');

      await tapControl(tester, 'toggle_answer_button');
      await tapControl(tester, 'got_it_button');

      await tapControl(tester, 'toggle_answer_button');
      await tapControl(tester, 'still_learning_button');
    }

    testWidgets('Completed results are saved before pressing Done', (
      tester,
    ) async {
      await openDeck(tester);
      await completeMixedSession(tester);

      final progress = store.progressForDeck(
        userId: 'mock_user',
        deckId: 'deck_001',
      );

      expect(progress.length, 2);

      expect(
        store
            .progressForCard(
              userId: 'mock_user',
              deckId: 'deck_001',
              cardId: 'card_001',
            )!
            .lastResult,
        StudyResult.gotIt,
      );

      await tapControl(tester, 'finish_study_button');

      expect(find.byType(DeckDetailsScreen), findsOneWidget);

      expect(
        tester.widget<Text>(find.byKey(const ValueKey('progress_Got It'))).data,
        '1',
      );
    });

    testWidgets('Targeted review updates only Still Learning cards', (
      tester,
    ) async {
      await openDeck(tester);
      await completeMixedSession(tester);

      await tapControl(tester, 'finish_study_button');

      await tapControl(tester, 'review_still_learning_button');

      final screen = tester.widget<StudySessionScreen>(
        find.byType(StudySessionScreen),
      );

      expect(screen.session.totalCards, 1);
      expect(screen.session.currentCard!.id, 'card_002');

      await tapControl(tester, 'toggle_answer_button');
      await tapControl(tester, 'got_it_button');
      await tapControl(tester, 'finish_study_button');

      expect(
        store.cardsNeedingReview(userId: 'mock_user', deckId: 'deck_001'),
        isEmpty,
      );

      final reviewButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('review_still_learning_button')),
      );

      expect(reviewButton.onPressed, isNull);

      expect(
        store.progressForDeck(userId: 'mock_user', deckId: 'deck_001').length,
        2,
      );
    });

    testWidgets('Incomplete session does not save progress', (tester) async {
      await openDeck(tester);

      await tapControl(tester, 'start_study_button');

      await tapControl(tester, 'toggle_answer_button');
      await tapControl(tester, 'got_it_button');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        store.progressForDeck(userId: 'mock_user', deckId: 'deck_001'),
        isEmpty,
      );
    });

    testWidgets('Study Again preserves previously saved progress', (
      tester,
    ) async {
      await openDeck(tester);
      await completeMixedSession(tester);

      await tapControl(tester, 'study_again_button');

      expect(
        store.progressForDeck(userId: 'mock_user', deckId: 'deck_001').length,
        2,
      );

      final screen = tester.widget<StudySessionScreen>(
        find.byType(StudySessionScreen),
      );

      expect(screen.session.reviewedCards, 0);
      expect(screen.session.isCompleted, isFalse);

      await tapControl(tester, 'toggle_answer_button');
      await tapControl(tester, 'still_learning_button');

      await tapControl(tester, 'toggle_answer_button');
      await tapControl(tester, 'got_it_button');

      expect(
        store
            .progressForCard(
              userId: 'mock_user',
              deckId: 'deck_001',
              cardId: 'card_001',
            )!
            .lastResult,
        StudyResult.stillLearning,
      );

      expect(
        store
            .progressForCard(
              userId: 'mock_user',
              deckId: 'deck_001',
              cardId: 'card_002',
            )!
            .lastResult,
        StudyResult.gotIt,
      );
    });
  });
}
