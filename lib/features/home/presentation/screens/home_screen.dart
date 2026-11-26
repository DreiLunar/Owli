import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/section_header.dart';
import '../../../../widgets/stat_tile.dart';

/// Home tab wireframe: greeting + avatar, "Continue Studying" banner,
/// "Jump back in" recent notes, progress stats, and card mastery bar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onResumeStudy,
    this.onViewAllNotes,
  });

  final VoidCallback? onResumeStudy;
  final VoidCallback? onViewAllNotes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Good Morning,', style: theme.textTheme.titleMedium),
                      Text('User!', style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person_outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // "Continue Studying" banner.
            // TODO(data): pick the user's most recently studied deck.
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Continue Studying',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'No deck studied yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: onResumeStudy,
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Jump back in',
              actionLabel: 'View All',
              onAction: onViewAllNotes,
            ),
            const SizedBox(height: AppSpacing.sm),
            // TODO(data): last 2 updated notes.
            const EmptyState(
              title: 'No notes yet',
              message: 'Your most recent notes will show up here.',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(title: 'Your progress so far'),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: <Widget>[
                Expanded(child: StatTile(label: 'Notes', value: '0')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: StatTile(label: 'Decks', value: '0')),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: StatTile(label: 'Learned', value: '0')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Card Mastery',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        Text(
                          '0 / 0 Cards',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      child: const LinearProgressIndicator(value: 0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
