import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/domain/services/study_session_controller.dart';
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

  Future<void> pumpStudyScreen(WidgetTester tester) async {
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
      await tester.pumpWidget(
        MaterialApp(
          home: DeckDetailsScreen(deck: store.decks.first, store: store),
        ),
      );

      final startButton = find.byKey(const ValueKey('start_study_button'));

      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.byType(StudySessionScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('study_flashcard')));

      await tester.pumpAndSettle();

      expect(find.text('ANSWER'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(DeckDetailsScreen), findsOneWidget);

      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.text('QUESTION'), findsOneWidget);

      expect(find.text('Card 1 of 2'), findsOneWidget);
    });

    testWidgets('Start study is disabled for an empty deck', (tester) async {
      final emptyDeck = store.createDeck(title: 'Empty Deck');

      await tester.pumpWidget(
        MaterialApp(
          home: DeckDetailsScreen(deck: emptyDeck, store: store),
        ),
      );

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
}
