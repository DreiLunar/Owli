import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:owli/features/auth/data/auth_providers.dart';
import 'package:owli/features/auth/presentation/login_screen.dart';
import 'package:owli/features/auth/presentation/signup_screen.dart';
import 'package:owli/features/dashboard/presentation/home_screen.dart';

/// Tells the router to re-run its redirect whenever login state changes.
class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _AuthRefresh(Stream<User?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref.read(authRepositoryProvider).authChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/signup';

      if (!loggedIn) return onAuthPage ? null : '/login';
      if (onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    ],
  );
});