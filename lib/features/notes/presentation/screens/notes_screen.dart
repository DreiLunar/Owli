import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/empty_state.dart';
import '../../domain/models/note_item.dart';
import '../widgets/new_subject_dialog.dart';
import 'note_editor_screen.dart';

/// Notes tab wireframe (`owli-1-notes-list`): header, search row, subject filter
/// chips, and note cards, wired to local UI state until Firestore CRUD lands.
class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    this.initialSubjects,
    this.initialNotes,
  });

  final List<SubjectItem>? initialSubjects;
  final List<NoteItem>? initialNotes;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final List<SubjectItem> _subjects = List<SubjectItem>.of(
    widget.initialSubjects ?? _defaultSubjects(),
  );
  late final List<NoteItem> _notes = List<NoteItem>.of(
    widget.initialNotes ?? _defaultNotes(),
  );

  String? _selectedSubjectId;
  String _searchQuery = '';
  int _nextId = 100;

  static List<SubjectItem> _defaultSubjects() => const <SubjectItem>[
    SubjectItem(id: 'math', name: 'Math', colorIndex: 0),
    SubjectItem(id: 'automata', name: 'Automata', colorIndex: 3),
  ];

  static List<NoteItem> _defaultNotes() {
    final DateTime twoHoursAgo = DateTime.now().subtract(
      const Duration(hours: 2),
    );
    return <NoteItem>[
      NoteItem(
        id: 'note-1',
        subjectId: 'automata',
        title: 'DFA Introduction',
        body:
            'A DFA reads input one symbol at a time and moves between states using a transition function.',
        updatedAt: twoHoursAgo,
      ),
      NoteItem(
        id: 'note-2',
        subjectId: 'automata',
        title: 'NFA and e-NFA',
        body:
            'NFAs allow several transitions per symbol, and e-NFAs can also move without reading input.',
        updatedAt: twoHoursAgo,
      ),
      NoteItem(
        id: 'note-3',
        subjectId: 'math',
        title: 'Linear Algebra Basics',
        body:
            'Vectors, matrices, and linear transformations: the basics for solving systems of equations.',
        updatedAt: twoHoursAgo,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  SubjectItem? _subjectForId(String subjectId) {
    for (final SubjectItem subject in _subjects) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }

  Color _colorForSubject(SubjectItem? subject) {
    final int idx = subject?.colorIndex ?? 0;
    return AppColors.subjectTags[idx % AppColors.subjectTags.length];
  }

  Future<void> _openNewSubjectDialog() async {
    final SubjectDraft? draft = await showNewSubjectDialog(context);
    if (!mounted || draft == null) return;

    // TODO(data): replace local append with Firestore subject creation.
    setState(() {
      final String id = 'subject-${_nextId++}';
      _subjects.add(
        SubjectItem(
          id: id,
          name: draft.name,
          colorIndex: draft.colorIndex,
        ),
      );
      _selectedSubjectId = id;
    });
  }

  Future<void> _openNewNote() async {
    if (_subjects.isEmpty) {
      await _openNewSubjectDialog();
      if (!mounted || _subjects.isEmpty) return;
    }

    final NoteEditorResult? result = await Navigator.of(context)
        .push<NoteEditorResult>(
          MaterialPageRoute<NoteEditorResult>(
            builder: (_) => NoteEditorScreen(
              subjects: _subjects,
              initialSubjectId: _selectedSubjectId,
            ),
          ),
        );

    if (!mounted || result == null) return;
    if (result.action == NoteEditorAction.saved) {
      // TODO(data): replace local insert with Firestore note creation.
      setState(() {
        _notes.insert(
          0,
          NoteItem(
            id: 'note-${_nextId++}',
            subjectId: result.subjectId!,
            title: result.title!,
            body: result.body!,
            updatedAt: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _openEditNote(NoteItem note) async {
    final NoteEditorResult? result = await Navigator.of(context)
        .push<NoteEditorResult>(
          MaterialPageRoute<NoteEditorResult>(
            builder: (_) => NoteEditorScreen(
              subjects: _subjects,
              initialNote: note,
            ),
          ),
        );

    if (!mounted || result == null) return;
    setState(() {
      if (result.action == NoteEditorAction.deleted) {
        _notes.removeWhere((NoteItem item) => item.id == note.id);
      } else if (result.action == NoteEditorAction.saved) {
        final int index = _notes.indexWhere(
          (NoteItem item) => item.id == note.id,
        );
        if (index != -1) {
          _notes[index] = note.copyWith(
            subjectId: result.subjectId,
            title: result.title,
            body: result.body,
            updatedAt: DateTime.now(),
          );
        }
      }
    });
  }

  Future<void> _deleteNoteFromMenu(NoteItem note) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: Text('Delete "${note.title}"?'),
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
    // TODO(data): delete note from Firestore under users/{uid}/notes/{noteId}.
    setState(() {
      _notes.removeWhere((NoteItem item) => item.id == note.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String query = _searchQuery.trim().toLowerCase();

    final List<NoteItem> filteredNotes = _notes.where((NoteItem note) {
      final bool matchesSubject =
          _selectedSubjectId == null || note.subjectId == _selectedSubjectId;
      final bool matchesQuery =
          query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.body.toLowerCase().contains(query);
      return matchesSubject && matchesQuery;
    }).toList();

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
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search notes',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: _openNewNote,
                  child: const Text('+ New Note'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Subject filter chips: "All Subjects", one per subject, "+ Subject".
            // TODO(data): stream subjects from users/{uid}/subjects.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('All Subjects'),
                    selected: _selectedSubjectId == null,
                    onSelected: (_) {
                      setState(() => _selectedSubjectId = null);
                    },
                  ),
                  ..._subjects.map((SubjectItem subject) {
                    final Color dotColor = _colorForSubject(subject);
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: ChoiceChip(
                        avatar: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: Text(subject.name),
                        selected: _selectedSubjectId == subject.id,
                        onSelected: (_) {
                          setState(() => _selectedSubjectId = subject.id);
                        },
                      ),
                    );
                  }),
                  const SizedBox(width: AppSpacing.sm),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Subject'),
                    onPressed: _openNewSubjectDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // TODO(data): stream notes from users/{uid}/notes.
            if (filteredNotes.isEmpty)
              EmptyState(
                title: _notes.isEmpty ? 'No notes yet' : 'No matching notes',
                message: _notes.isEmpty
                    ? 'Tap + New Note to write your first study note.'
                    : 'Try another search term or subject filter.',
                icon: Icons.description_outlined,
              )
            else
              ...filteredNotes.map(_buildNoteCard),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    final ThemeData theme = Theme.of(context);
    final SubjectItem? subject = _subjectForId(note.subjectId);
    final Color tagColor = _colorForSubject(subject);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openEditNote(note),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Chip(
                      avatar: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: Text(subject?.name ?? 'Subject'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (String value) {
                        if (value == 'edit') {
                          _openEditNote(note);
                        } else if (value == 'delete') {
                          _deleteNoteFromMenu(note);
                        }
                      },
                      itemBuilder: (_) => const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(note.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Last edited: ${note.formattedLastEdited()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
