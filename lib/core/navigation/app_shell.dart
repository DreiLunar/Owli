import 'package:material_ui/material_ui.dart';

import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/flashcards/domain/repositories/study_repository.dart';
import '../../features/flashcards/presentation/screens/deck_library_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notes/presentation/screens/notes_screen.dart';

import 'app_routes.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialIndex = 0,
    this.studyRepository,
    this.studySubjectId,
  }) : assert(studyRepository == null || studySubjectId != null);

  final int initialIndex;
  final StudyRepository? studyRepository;
  final String? studySubjectId;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _selectTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.studyRepository;

    final List<Widget> tabs = <Widget>[
      HomeScreen(
        onViewAllNotes: () => _selectTab(1),
        onResumeStudy: () => _selectTab(2),
      ),

      const NotesScreen(),

      if (repository == null)
        const DeckLibraryScreen()
      else
        DeckLibraryScreen.withRepository(
          key: ValueKey(repository.userId),
          repository: repository,
          subjectId: widget.studySubjectId!,
        ),

      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: AppTabs.destinations,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}
