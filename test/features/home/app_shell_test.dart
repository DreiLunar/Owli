import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:owli/core/navigation/app_shell.dart';
import 'package:owli/core/theme/app_theme.dart';

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

    // Bottom navigation destinations.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Notes'), findsWidgets);
    expect(find.text('Study'), findsWidgets);
    expect(find.text('Account'), findsOneWidget);

    // Home tab content renders without layout errors.
    expect(find.text('Good Morning,'), findsOneWidget);
    expect(find.text('Continue Studying'), findsOneWidget);

    // Switch to Notes tab.
    await tester.tap(find.text('Notes').last);
    await tester.pumpAndSettle();
    expect(find.text('Your Little Library'), findsOneWidget);

    // Switch to Study tab (DeckLibraryScreen).
    await tester.tap(find.text('Study').last);
    await tester.pumpAndSettle();
    expect(find.text('My Decks'), findsOneWidget);

    // Switch to Account tab.
    await tester.tap(find.text('Account').last);
    await tester.pumpAndSettle();
    expect(find.text('Sign Out'), findsOneWidget);
  });

  test('AppTheme builds light and dark color schemes', () {
    expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });
}
