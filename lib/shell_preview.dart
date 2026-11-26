import 'package:material_ui/material_ui.dart';

import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ShellPreviewApp());
}

/// Firebase-free preview entrypoint for inspecting the 4-tab [AppShell]
/// (Home, Notes, Study, Account) and the Notes/Subject wireframe flows.
class ShellPreviewApp extends StatelessWidget {
  const ShellPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owli Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
