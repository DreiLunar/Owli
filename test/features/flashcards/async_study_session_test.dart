import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';
import 'package:owli/features/flashcards/domain/models/study_progress.dart';
import 'package:owli/features/flashcards/domain/services/study_session_controller.dart';
import 'package:owli/features/flashcards/presentation/screens/study_session_screen.dart';

void main() {
  late MockStudyStore store;
  late StudySessionController session;

  setUp(() {
    store = MockStudyStore();

    session = StudySessionController(
      deckId: 'deck_001',
      cards: [store.cardsForDeck('deck_001').first],
    );
  });

  Future<void> configureViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> pumpStudyScreen(
    WidgetTester tester, {
    FutureOr<void> Function(Map<String, StudyResult>)? onCompleted,
  }) async {
    await configureViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionScreen(
          deckTitle: 'Automata Theory',
          session: session,
          onSessionCompleted: onCompleted,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> finishSession(WidgetTester tester) async {
    final toggle = find.byKey(const ValueKey('toggle_answer_button'));

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final gotIt = find.byKey(const ValueKey('got_it_button'));

    await tester.ensureVisible(gotIt);
    await tester.tap(gotIt);

    // Do not pumpAndSettle while a loading
    // indicator may be animating.
    await tester.pump();
  }

  group('Asynchronous Session Saving', () {
    // TEST 1
    testWidgets('Shows saving state until persistence completes', (
      tester,
    ) async {
      final pending = Completer<void>();

      var saveCalls = 0;

      await pumpStudyScreen(
        tester,

        onCompleted: (results) {
          saveCalls++;
          return pending.future;
        },
      );

      await finishSession(tester);

      expect(saveCalls, 1);

      expect(
        find.byKey(const ValueKey('session_saving_state')),
        findsOneWidget,
      );

      expect(find.text('Session completed!'), findsNothing);

      expect(find.byKey(const ValueKey('finish_study_button')), findsNothing);

      final popScope = tester.widget<PopScope<void>>(
        find.byType(PopScope<void>),
      );

      expect(popScope.canPop, isFalse);

      pending.complete();

      await tester.pumpAndSettle();

      expect(find.text('Session completed!'), findsOneWidget);

      expect(find.byKey(const ValueKey('session_saving_state')), findsNothing);
    });

    // TEST 2
    testWidgets('Failed saving preserves study outcomes', (tester) async {
      await pumpStudyScreen(
        tester,

        onCompleted: (results) async {
          throw StateError('Simulated failure');
        },
      );

      await finishSession(tester);
      await tester.pumpAndSettle();

      expect(session.isCompleted, isTrue);
      expect(session.results.length, 1);

      expect(session.results.values.single, StudyResult.gotIt);

      expect(find.byKey(const ValueKey('session_save_error')), findsOneWidget);

      expect(find.text('Session completed!'), findsNothing);
    });

    // TEST 3
    testWidgets('Retry saves the same results without duplicate calls', (
      tester,
    ) async {
      var attempts = 0;

      final pendingRetry = Completer<void>();

      final submitted = <Map<String, StudyResult>>[];

      await pumpStudyScreen(
        tester,

        onCompleted: (results) {
          attempts++;

          submitted.add(Map<String, StudyResult>.of(results));

          if (attempts == 1) {
            throw StateError('First save failed');
          }

          return pendingRetry.future;
        },
      );

      await finishSession(tester);
      await tester.pumpAndSettle();

      expect(attempts, 1);

      final retryFinder = find.byKey(const ValueKey('retry_session_save'));

      final retryButton = tester.widget<FilledButton>(retryFinder);

      // Simulate duplicate button callbacks.
      retryButton.onPressed!();
      retryButton.onPressed!();

      await tester.pump();

      expect(attempts, 2);
      expect(submitted[0], equals(submitted[1]));

      pendingRetry.complete();

      await tester.pumpAndSettle();

      expect(find.text('Session completed!'), findsOneWidget);

      expect(find.byKey(const ValueKey('session_save_error')), findsNothing);
    });

    // TEST 4
    testWidgets('User can leave after an unsuccessful save', (tester) async {
      await configureViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => StudySessionScreen(
                          deckTitle: 'Test Deck',
                          session: session,

                          onSessionCompleted: (results) async {
                            throw StateError('Save failed');
                          },
                        ),
                      ),
                    );
                  },

                  child: const Text('Open Study'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Study'));

      await tester.pumpAndSettle();

      await finishSession(tester);
      await tester.pumpAndSettle();

      final leaveButton = find.byKey(const ValueKey('discard_session_results'));

      await tester.ensureVisible(leaveButton);
      await tester.tap(leaveButton);

      await tester.pumpAndSettle();

      expect(find.byType(StudySessionScreen), findsNothing);

      expect(find.text('Open Study'), findsOneWidget);
    });

    // TEST 5
    testWidgets('Incomplete study does not call persistence', (tester) async {
      var saveCalls = 0;

      await pumpStudyScreen(
        tester,

        onCompleted: (results) {
          saveCalls++;
        },
      );

      final toggle = find.byKey(const ValueKey('toggle_answer_button'));

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(saveCalls, 0);
      expect(session.isCompleted, isFalse);
    });

    // TEST 6
    testWidgets('Study Again resets the asynchronous save state', (
      tester,
    ) async {
      var saveCalls = 0;

      await pumpStudyScreen(
        tester,

        onCompleted: (results) async {
          saveCalls++;
        },
      );

      await finishSession(tester);
      await tester.pumpAndSettle();

      expect(saveCalls, 1);

      final restart = find.byKey(const ValueKey('study_again_button'));

      await tester.ensureVisible(restart);
      await tester.tap(restart);
      await tester.pumpAndSettle();

      expect(session.isCompleted, isFalse);
      expect(session.results, isEmpty);

      await finishSession(tester);
      await tester.pumpAndSettle();

      expect(saveCalls, 2);

      expect(find.text('Session completed!'), findsOneWidget);
    });

    // TEST 7
    testWidgets('Finishing a save after disposal causes no error', (
      tester,
    ) async {
      final pending = Completer<void>();

      await pumpStudyScreen(tester, onCompleted: (_) => pending.future);

      await finishSession(tester);

      await tester.pumpWidget(const SizedBox.shrink());

      pending.complete();

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
