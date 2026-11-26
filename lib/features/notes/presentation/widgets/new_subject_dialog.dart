import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SubjectDraft {
  const SubjectDraft({required this.name, required this.colorIndex});

  final String name;
  final int colorIndex;
}

/// New Subject modal matching wireframe `owli-4-new-subject-modal`.
Future<SubjectDraft?> showNewSubjectDialog(BuildContext context) {
  return showDialog<SubjectDraft>(
    context: context,
    builder: (_) => const NewSubjectDialog(),
  );
}

class NewSubjectDialog extends StatefulWidget {
  const NewSubjectDialog({super.key});

  @override
  State<NewSubjectDialog> createState() => _NewSubjectDialogState();
}

class _NewSubjectDialogState extends State<NewSubjectDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(data): create subject in Firestore under users/{uid}/subjects.
    Navigator.of(context).pop(
      SubjectDraft(
        name: _nameController.text.trim(),
        colorIndex: _selectedColorIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('New Subject', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Text('Subject Name', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  hintText: 'Enter subject name...',
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a subject name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Color tag', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: List<Widget>.generate(AppColors.subjectTags.length, (
                  int index,
                ) {
                  final Color swatch = AppColors.subjectTags[index];
                  final bool isSelected = index == _selectedColorIndex;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < AppColors.subjectTags.length - 1
                          ? AppSpacing.md
                          : 0,
                    ),
                    child: InkResponse(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      radius: 24,
                      child: Semantics(
                        label: 'Color tag ${index + 1}',
                        selected: isSelected,
                        button: true,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
