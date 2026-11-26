import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/note_item.dart';

enum NoteEditorAction { saved, deleted }

class NoteEditorResult {
  const NoteEditorResult._({
    required this.action,
    this.subjectId,
    this.title,
    this.body,
  });

  const NoteEditorResult.saved({
    required String subjectId,
    required String title,
    required String body,
  }) : this._(
         action: NoteEditorAction.saved,
         subjectId: subjectId,
         title: title,
         body: body,
       );

  const NoteEditorResult.deleted() : this._(action: NoteEditorAction.deleted);

  final NoteEditorAction action;
  final String? subjectId;
  final String? title;
  final String? body;
}

/// Create / Edit Note screen matching wireframes `owli-2-create-note` and
/// `owli-3-edit-note`.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.subjects,
    this.initialNote,
    this.initialSubjectId,
  });

  final List<SubjectItem> subjects;
  final NoteItem? initialNote;
  final String? initialSubjectId;

  bool get isEditing => initialNote != null;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialNote?.title ?? '',
  );
  late final TextEditingController _bodyController = TextEditingController(
    text: widget.initialNote?.body ?? '',
  );

  late String? _selectedSubjectId = _resolveInitialSubjectId();

  String? _resolveInitialSubjectId() {
    final String? candidate =
        widget.initialNote?.subjectId ?? widget.initialSubjectId;
    if (candidate != null &&
        widget.subjects.any((SubjectItem s) => s.id == candidate)) {
      return candidate;
    }
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) return;

    if (widget.isEditing) {
      // TODO(data): update note in Firestore under users/{uid}/notes/{noteId}.
    } else {
      // TODO(data): create note in Firestore under users/{uid}/notes.
    }

    Navigator.of(context).pop(
      NoteEditorResult.saved(
        subjectId: _selectedSubjectId!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text('This note will be permanently removed.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;
    // TODO(data): delete note in Firestore under users/{uid}/notes/{noteId}.
    Navigator.of(context).pop(const NoteEditorResult.deleted());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.isEditing ? 'Edit Note' : 'New Note'),
        actions: <Widget>[
          if (widget.isEditing)
            IconButton(
              onPressed: _confirmDelete,
              tooltip: 'Delete note',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Subject', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select a subject...',
                      ),
                      items: widget.subjects
                          .map(
                            (SubjectItem subject) => DropdownMenuItem<String>(
                              value: subject.id,
                              child: Text(subject.name),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() => _selectedSubjectId = value);
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text('Title', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Enter note title...',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a note title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text('Notes', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _bodyController,
                      minLines: 10,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Write your plain-text notes here...',
                        alignLabelWithHint: true,
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter note content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton(
                      onPressed: _save,
                      child: Text(widget.isEditing ? 'Save Changes' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
