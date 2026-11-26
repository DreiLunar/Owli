import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:owli/core/navigation/app_shell.dart';
import 'package:owli/core/theme/app_theme.dart';
import 'package:owli/features/flashcards/data/repositories/mock_study_repository.dart';

void main() {
  testWidgets('AppShell renders 4 tabs and switches between screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const AppShell(),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Notes'), findsWidgets);
    expect(find.text('Study'), findsWidgets);
    expect(find.text('Account'), findsOneWidget);

    expect(find.text('Good Morning,'), findsOneWidget);

    expect(find.text('Continue Studying'), findsOneWidget);

    await tester.tap(find.text('Notes').last);
    await tester.pumpAndSettle();

    expect(find.text('Your Little Library'), findsOneWidget);

    await tester.tap(find.text('Study').last);
    await tester.pumpAndSettle();

    expect(find.text('My Decks'), findsOneWidget);

    await tester.tap(find.text('Account').last);
    await tester.pumpAndSettle();

    expect(find.text('Sign Out'), findsOneWidget);
  });

  // TEST 2 — Existing theme test
  test('AppTheme builds light and dark color schemes', () {
    expect(AppTheme.light.colorScheme.brightness, Brightness.light);

    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });

  // TEST 3 — New Study repository integration test
  testWidgets('Study tab uses the injected repository', (
    WidgetTester tester,
  ) async {
    final repository = MockStudyRepository(userId: 'integration_user');

    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppShell(
          initialIndex: 2,
          studyRepository: repository,
          studySubjectId: 'general',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0 Decks'), findsOneWidget);

    expect(find.text('No decks yet'), findsOneWidget);

    expect(find.text('Automata Theory'), findsNothing);
  });
}
