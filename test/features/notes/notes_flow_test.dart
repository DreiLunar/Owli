import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:owli/core/theme/app_theme.dart';
import 'package:owli/features/notes/domain/models/note_item.dart';
import 'package:owli/features/notes/presentation/screens/notes_screen.dart';

Widget _wrapNotesScreen({
  List<SubjectItem>? initialSubjects,
  List<NoteItem>? initialNotes,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: NotesScreen(
      initialSubjects: initialSubjects,
      initialNotes: initialNotes,
    ),
  );
}

void main() {
  testWidgets('New Subject modal adds a subject chip with color tag', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrapNotesScreen());

    await tester.tap(find.text('Subject'));
    await tester.pumpAndSettle();

    expect(find.text('New Subject'), findsOneWidget);
    expect(find.text('Subject Name'), findsOneWidget);
    expect(find.text('Color tag'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Color tag 2'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter subject name...'),
      'Biology',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Biology'), findsOneWidget);
  });

  testWidgets('New Note screen creates and displays a note', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrapNotesScreen(initialNotes: const <NoteItem>[]));

    expect(find.text('No notes yet'), findsOneWidget);

    await tester.tap(find.text('+ New Note'));
    await tester.pumpAndSettle();

    expect(find.text('New Note'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Math').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter note title...'),
      'Eigenvalues',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Write your plain-text notes here...'),
      'Scalar values associated with eigenvectors.',
    );

    final Finder saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Eigenvalues'), findsOneWidget);
    expect(
      find.text('Scalar values associated with eigenvectors.'),
      findsOneWidget,
    );
  });

  testWidgets('Edit Note screen updates and deletes a note', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrapNotesScreen());

    await tester.tap(find.text('DFA Introduction'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter note title...'),
      'DFA State Machines',
    );
    final Finder saveChangesButton = find.widgetWithText(
      FilledButton,
      'Save Changes',
    );
    await tester.ensureVisible(saveChangesButton);
    await tester.tap(saveChangesButton);
    await tester.pumpAndSettle();

    expect(find.text('DFA State Machines'), findsOneWidget);
    expect(find.text('DFA Introduction'), findsNothing);

    await tester.tap(find.text('DFA State Machines'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();

    expect(find.text('Delete note?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('DFA State Machines'), findsNothing);
  });
}
