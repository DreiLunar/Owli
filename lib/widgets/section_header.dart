import 'package:material_ui/material_ui.dart';

/// Row with a section title and an optional trailing text action, matching
/// the "Jump back in / View All" and "Cards (12) / + Add Card" headers in the
/// wireframes.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
