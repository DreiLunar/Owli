import 'package:material_ui/material_ui.dart';

/// Named routes for the MVP flow:
/// Sign in -> 4-tab shell -> Notes/Deck detail -> Study session.
///
/// The auth gate decides between [splash], [login] and [home], so no screen
/// pushes the login route directly.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String home = '/home';

  // Tab shell destinations (used as branch keys by the tab navigator).
  static const String dashboard = '/home/dashboard';
  static const String notes = '/home/notes';
  static const String decks = '/home/decks';
  static const String account = '/home/account';

  // Pushed on top of the tab shell.
  static const String noteEditor = '/note';
  static const String subjectEditor = '/subject';
  static const String deckDetail = '/deck';
  static const String deckEditor = '/deck/edit';
  static const String study = '/study';
  static const String sessionComplete = '/study/complete';
}

/// Bottom navigation destinations, in the order of the wireframes:
/// Home | Notes | Study | Account.
class AppTabs {
  const AppTabs._();

  static const List<NavigationDestination> destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style),
      label: 'Study',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Account',
    ),
  ];
}
