import 'package:material_ui/material_ui.dart';

import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/flashcards/presentation/screens/deck_library_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notes/presentation/screens/notes_screen.dart';
import 'app_routes.dart';

/// Shared 4-tab bottom navigation shell: Home | Notes | Study | Account.
///
/// Tabs are kept in an [IndexedStack] so switching tabs preserves scroll state.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

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
    final List<Widget> tabs = <Widget>[
      HomeScreen(
        onViewAllNotes: () => _selectTab(1),
        onResumeStudy: () => _selectTab(2),
      ),
      const NotesScreen(),
      const DeckLibraryScreen(),
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
