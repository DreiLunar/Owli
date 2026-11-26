import 'package:material_ui/material_ui.dart';

import '../core/theme/app_spacing.dart';

/// One number + caption box used by the dashboard's "Your progress so far"
/// row (Notes / Decks / Learned).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: <Widget>[
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
