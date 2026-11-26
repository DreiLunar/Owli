import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/data/repositories/mock_study_repository.dart';
import 'package:owli/features/flashcards/domain/models/deck.dart';
import 'package:owli/features/flashcards/presentation/screens/create_deck_screen.dart';
import 'package:owli/features/flashcards/presentation/screens/deck_library_screen.dart';

class ControlledRepository extends MockStudyRepository {
  ControlledRepository({required super.store, super.userId});

  Completer<void>? loadGate;
  Completer<void>? saveGate;

  bool failReads = false;
  bool failWrites = false;

  int fetchCalls = 0;
  int createCalls = 0;

  String? lastSubjectId;

  @override
  Future<List<Deck>> fetchDecks() async {
    fetchCalls++;

    await loadGate?.future;

    if (failReads) {
      throw StateError('Simulated read failure');
    }

    return super.fetchDecks();
  }

  @override
  Future<void> createDeck({
    required String subjectId,
    required String title,
    String description = '',
  }) async {
    createCalls++;
    lastSubjectId = subjectId;

    await saveGate?.future;

    if (failWrites) {
      throw StateError('Simulated write failure');
    }

    await super.createDeck(
      subjectId: subjectId,
      title: title,
      description: description,
    );
  }
}

void main() {
  late MockStudyStore store;
  late ControlledRepository repository;

  setUp(() {
    store = MockStudyStore();

    repository = ControlledRepository(store: store);
  });

  const createKey = ValueKey('create_deck_button');

  const submitKey = ValueKey('submit_deck_button');

  Future<void> pumpLibrary(WidgetTester tester, {bool settle = true}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DeckLibraryScreen.withRepository(
          repository: repository,
          subjectId: 'subject_test',

          detailsBuilder: (context, deck) {
            return Scaffold(
              appBar: AppBar(title: Text(deck.title)),

              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    await repository.createFlashcard(
                      deckId: deck.id,
                      front: 'New question',
                      back: 'New answer',
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },

                  child: const Text('Add test card'),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  Future<void> openCreateForm(WidgetTester tester) async {
    await tester.tap(find.byKey(createKey));
    await tester.pumpAndSettle();

    expect(find.byType(CreateDeckScreen), findsOneWidget);
  }

  Future<void> enterDraft(WidgetTester tester) async {
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Data Structures');

    await tester.enterText(fields.at(1), 'Trees and graphs');

    await tester.ensureVisible(find.byKey(submitKey));
  }

  group('Asynchronous Deck Library', () {
    // TEST 1
    testWidgets('Shows loading until repository returns decks', (tester) async {
      final pending = Completer<void>();

      repository.loadGate = pending;

      await pumpLibrary(tester, settle: false);

      expect(
        find.byKey(const ValueKey('library_loading_state')),
        findsOneWidget,
      );

      expect(find.text('My Decks'), findsNothing);

      final createButton = tester.widget<FloatingActionButton>(
        find.byKey(createKey),
      );

      expect(createButton.onPressed, isNull);

      pending.complete();

      await tester.pumpAndSettle();

      expect(find.text('My Decks'), findsOneWidget);

      expect(find.text('3 Decks'), findsOneWidget);

      expect(find.text('6 flashcards to explore'), findsOneWidget);
    });

    // TEST 2
    testWidgets('Failed library retrieval can be retried', (tester) async {
      repository.failReads = true;

      await pumpLibrary(tester);

      expect(find.byKey(const ValueKey('library_error_state')), findsOneWidget);

      repository.failReads = false;

      await tester.tap(find.byKey(const ValueKey('retry_library_button')));

      await tester.pumpAndSettle();

      expect(find.text('3 Decks'), findsOneWidget);

      expect(repository.fetchCalls, 2);
    });

    // TEST 3
    testWidgets('Displays an empty library for a new user', (tester) async {
      repository = ControlledRepository(store: store, userId: 'new_user');

      await pumpLibrary(tester);

      expect(find.text('0 Decks'), findsOneWidget);

      expect(find.text('No decks yet'), findsOneWidget);

      expect(find.text('0 flashcards to explore'), findsOneWidget);
    });

    // TEST 4
    testWidgets('Search filters decks without extra reads', (tester) async {
      await pumpLibrary(tester);

      final originalCalls = repository.fetchCalls;

      final search = find.byKey(const ValueKey('deck_search_field'));

      await tester.enterText(search, 'automata');

      await tester.pumpAndSettle();

      expect(find.text('Automata Theory'), findsOneWidget);

      expect(find.text('Mobile Computing'), findsNothing);

      await tester.enterText(search, 'unknown-deck');

      await tester.pumpAndSettle();

      expect(find.text('No decks found'), findsOneWidget);

      expect(repository.fetchCalls, originalCalls);
    });

    // TEST 5
    testWidgets('Creates deck through repository with subject ID', (
      tester,
    ) async {
      await pumpLibrary(tester);
      await openCreateForm(tester);
      await enterDraft(tester);

      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);

      expect(repository.lastSubjectId, 'subject_test');

      expect(find.byType(CreateDeckScreen), findsNothing);

      expect(find.text('4 Decks'), findsOneWidget);

      expect(find.text('Data Structures'), findsOneWidget);

      final created = store.decks.singleWhere(
        (deck) => deck.title == 'Data Structures',
      );

      expect(created.subjectId, 'subject_test');
      expect(created.description, 'Trees and graphs');
    });

    // TEST 6
    testWidgets('Failed creation preserves draft and allows retry', (
      tester,
    ) async {
      repository.failWrites = true;

      await pumpLibrary(tester);
      await openCreateForm(tester);
      await enterDraft(tester);

      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('deck_save_error')), findsOneWidget);

      expect(find.byType(CreateDeckScreen), findsOneWidget);

      final titleField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );

      expect(titleField.controller!.text, 'Data Structures');

      expect(store.decks.length, 3);

      repository.failWrites = false;

      await tester.ensureVisible(find.byKey(submitKey));

      await tester.tap(find.byKey(submitKey));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 2);
      expect(store.decks.length, 4);

      expect(find.byType(CreateDeckScreen), findsNothing);
    });

    // TEST 7
    testWidgets('Prevents duplicate submission while saving', (tester) async {
      final pending = Completer<void>();

      repository.saveGate = pending;

      await pumpLibrary(tester);
      await openCreateForm(tester);
      await enterDraft(tester);

      final submit = tester.widget<FilledButton>(find.byKey(submitKey));

      final callback = submit.onPressed!;

      callback();
      callback();

      await tester.pump();

      expect(repository.createCalls, 1);

      expect(find.byKey(const ValueKey('deck_saving_state')), findsOneWidget);

      expect(
        tester.widget<FilledButton>(find.byKey(submitKey)).onPressed,
        isNull,
      );

      pending.complete();

      await tester.pumpAndSettle();

      expect(store.decks.length, 4);
      expect(repository.createCalls, 1);
    });

    // TEST 8
    testWidgets('Returning from details reloads card counts', (tester) async {
      await pumpLibrary(tester);

      final originalCalls = repository.fetchCalls;

      final deckCard = find.byKey(const ValueKey('library_deck_deck_001'));

      await tester.ensureVisible(deckCard);
      await tester.tap(deckCard);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add test card'));

      await tester.pumpAndSettle();

      expect(find.text('7 flashcards to explore'), findsOneWidget);

      expect(repository.fetchCalls, originalCalls + 1);
    });

    // TEST 9
    testWidgets('Manual refresh retrieves current data', (tester) async {
      await pumpLibrary(tester);

      store.createDeck(title: 'External Deck');

      await tester.tap(find.byKey(const ValueKey('refresh_library_button')));

      await tester.pumpAndSettle();

      expect(find.text('4 Decks'), findsOneWidget);

      expect(find.text('External Deck'), findsOneWidget);
    });

    // TEST 10
    testWidgets('Pending retrieval is safe after disposal', (tester) async {
      final pending = Completer<void>();

      repository.loadGate = pending;

      await pumpLibrary(tester, settle: false);

      await tester.pumpWidget(const SizedBox.shrink());

      pending.complete();

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
