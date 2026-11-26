import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/data/auth_repository.dart';

/// Account tab wireframe: profile card, app info card, and sign-out action.
class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    this.displayName,
    this.email,
    this.onSignOut,
  });

  final String? displayName;
  final String? email;
  final VoidCallback? onSignOut;

  User? get _currentUser =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final User? user = _currentUser;
    final String resolvedName = displayName ??
        ((user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!
            : 'User Name');
    final String resolvedEmail = email ??
        ((user?.email?.trim().isNotEmpty ?? false)
            ? user!.email!
            : 'student@email.com');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: <Widget>[
            Text('Account', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(radius: 32, child: Icon(Icons.person)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(resolvedName, style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            resolvedEmail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('App Info', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'App Version: v1.0.0 (MVP)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      user != null
                          ? 'Sync Status: signed in'
                          : 'Sync Status: not connected',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            OutlinedButton(
              onPressed: () async {
                if (onSignOut != null) {
                  onSignOut!();
                  return;
                }
                if (Firebase.apps.isNotEmpty) {
                  await AuthRepository().signOut();
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
