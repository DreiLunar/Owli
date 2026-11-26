import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/data/repositories/mock_study_repository.dart';
import 'package:owli/features/flashcards/domain/models/flashcard.dart';
import 'package:owli/features/flashcards/presentation/screens/deck_details_screen.dart';
import 'package:owli/features/flashcards/presentation/screens/create_flashcard_screen.dart';
import 'package:owli/features/flashcards/presentation/screens/study_session_screen.dart';

class ControlledDetailsRepository extends MockStudyRepository {
  ControlledDetailsRepository({required super.store});

  Completer<void>? loadGate;

  bool failReads = false;
  bool failCreates = false;
  bool failDeletes = false;

  @override
  Future<List<Flashcard>> fetchFlashcards({required String deckId}) async {
    await loadGate?.future;

    if (failReads) {
      throw StateError('Simulated read failure');
    }

    return super.fetchFlashcards(deckId: deckId);
  }

  @override
  Future<void> createFlashcard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    if (failCreates) {
      throw StateError('Simulated create failure');
    }

    await super.createFlashcard(deckId: deckId, front: front, back: back);
  }

  @override
  Future<void> deleteFlashcard({
    required String deckId,
    required String cardId,
  }) async {
    if (failDeletes) {
      throw StateError('Simulated delete failure');
    }

    await super.deleteFlashcard(deckId: deckId, cardId: cardId);
  }
}

void main() {
  late MockStudyStore store;
  late ControlledDetailsRepository repository;

  setUp(() {
    store = MockStudyStore();
    repository = ControlledDetailsRepository(store: store);
  });

  Future<void> pumpDetails(
    WidgetTester tester, {
    String deckId = 'deck_001',
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    final deck = store.decks.singleWhere((item) => item.id == deckId);

    await tester.pumpWidget(
      MaterialApp(
        home: DeckDetailsScreen.withRepository(
          deck: deck,
          repository: repository,
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
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

  // TEST 1
  testWidgets('Shows loading and disables actions until loaded', (
    tester,
  ) async {
    final pending = Completer<void>();

    repository.loadGate = pending;

    await pumpDetails(tester, settle: false);

    expect(find.byKey(const ValueKey('details_loading_state')), findsOneWidget);

    final addButton = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey('add_flashcard_button')),
    );

    expect(addButton.onPressed, isNull);

    pending.complete();

    await tester.pumpAndSettle();

    expect(find.text('2 flashcards'), findsOneWidget);

    expect(find.text('Learning Progress'), findsOneWidget);
  });

  // TEST 2
  testWidgets('Read failure can be retried', (tester) async {
    repository.failReads = true;

    await pumpDetails(tester);

    expect(find.byKey(const ValueKey('details_error_state')), findsOneWidget);

    repository.failReads = false;

    await tapVisible(
      tester,
      find.byKey(const ValueKey('retry_details_button')),
    );

    expect(find.text('2 flashcards'), findsOneWidget);
  });

  // TEST 3
  testWidgets('Failed card creation preserves draft and retries', (
    tester,
  ) async {
    repository.failCreates = true;

    await pumpDetails(tester);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('add_flashcard_button')),
    );

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'New question');

    await tester.enterText(fields.at(1), 'New answer');

    final submit = find.byKey(const ValueKey('submit_flashcard_button'));

    await tapVisible(tester, submit);

    expect(find.byType(CreateFlashcardScreen), findsOneWidget);

    expect(find.byKey(const ValueKey('flashcard_save_error')), findsOneWidget);

    expect(store.cardCountForDeck('deck_001'), 2);

    final field = tester.widget<TextFormField>(fields.first);

    expect(field.controller!.text, 'New question');

    repository.failCreates = false;

    await tapVisible(tester, submit);

    expect(find.byType(CreateFlashcardScreen), findsNothing);

    expect(store.cardCountForDeck('deck_001'), 3);

    expect(find.text('3 flashcards'), findsOneWidget);
  });

  // TEST 4
  testWidgets('Empty deck cannot start a study session', (tester) async {
    final empty = store.createDeck(title: 'Empty Deck');

    await pumpDetails(tester, deckId: empty.id);

    final start = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start_study_button')),
    );

    expect(start.onPressed, isNull);
    expect(find.text('No flashcards yet'), findsOneWidget);
  });

  // TEST 5
  testWidgets('Large deck allows selecting a later batch', (tester) async {
    // Two seeded cards plus nine new cards.
    for (var i = 0; i < 9; i++) {
      store.createFlashcard(
        deckId: 'deck_001',
        front: 'Question $i',
        back: 'Answer $i',
      );
    }

    final lastCard = store.cardsForDeck('deck_001').last;

    await pumpDetails(tester);

    await tapVisible(tester, find.byKey(const ValueKey('start_study_button')));

    await tapVisible(tester, find.byKey(const ValueKey('study_batch_1')));

    final screen = tester.widget<StudySessionScreen>(
      find.byType(StudySessionScreen),
    );

    expect(screen.session.totalCards, 1);

    expect(screen.session.currentCard!.id, lastCard.id);
  });

  // TEST 6
  testWidgets('Failed deletion does not remove card from UI', (tester) async {
    repository.failDeletes = true;

    await pumpDetails(tester);

    final card = find.byKey(const ValueKey('card_001'));

    final deleteButton = find.descendant(
      of: card,
      matching: find.byTooltip('Delete flashcard'),
    );

    await tapVisible(tester, deleteButton);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.cardCountForDeck('deck_001'), 2);

    expect(find.text('2 flashcards'), findsOneWidget);

    repository.failDeletes = false;

    await tapVisible(tester, deleteButton);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.cardCountForDeck('deck_001'), 1);

    expect(find.text('1 flashcards'), findsOneWidget);
  });
}
