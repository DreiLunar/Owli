import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';

/// Notes tab wireframe: header, search row, subject filter chips, and note cards.
///
/// TODO(data): wire subject chips and note list to Firestore CRUD streams.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Your Little Library',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Catch a thought. Make it something wonderful.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
            const Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Search notes',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: null,
                  child: Text('+ New Note'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Subject filter chips: "All Subjects", then one per subject.
            // TODO(data): build chips from the user's subjects.
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  Chip(label: Text('All Subjects')),
                  SizedBox(width: AppSpacing.sm),
                  ActionChip(
                    avatar: Icon(Icons.add, size: 16),
                    label: Text('Subject'),
                    onPressed: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // TODO(data): note cards stream; empty/loading/error states ready.
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Chip(label: Text('Subject')),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Note title', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your note preview shows here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
