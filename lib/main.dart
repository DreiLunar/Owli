import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/sign_in_screen.dart';
import 'features/flashcards/data/repositories/firebase_study_repository.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.authChanges});

  final Stream<User?>? authChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authChanges ?? FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        final Widget home;
        final String applicationKey;

        if (snapshot.hasError) {
          applicationKey = 'auth-error';

          home = const Scaffold(
            body: Center(child: Text('Could not check sign-in status.')),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          applicationKey = 'auth-loading';

          home = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.data == null) {
          applicationKey = 'signed-out';
          home = const SignInScreen();
        } else {
          final user = snapshot.data!;

          applicationKey = 'signed-in:${user.uid}';

          home = AuthenticatedAppShell(key: ValueKey(user.uid));
        }

        return MaterialApp(
          key: ValueKey(applicationKey),
          title: 'Owli',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: home,
        );
      },
    );
  }
}

class AuthenticatedAppShell extends StatefulWidget {
  const AuthenticatedAppShell({super.key});

  @override
  State<AuthenticatedAppShell> createState() => _AuthenticatedAppShellState();
}

class _AuthenticatedAppShellState extends State<AuthenticatedAppShell> {
  late final FirebaseStudyRepository _studyRepository;

  @override
  void initState() {
    super.initState();

    _studyRepository = FirebaseStudyRepository();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      studyRepository: _studyRepository,

      // Temporary shared subject identifier.
      studySubjectId: 'general',
    );
  }
}
