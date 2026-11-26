/// Lightweight UI models for the Notes & Subjects wireframe flow.
///
/// TODO(data): replace with Firestore-backed models/providers when
/// `users/{uid}/subjects` and `users/{uid}/notes` services land.
class SubjectItem {
  const SubjectItem({
    required this.id,
    required this.name,
    this.colorIndex = 0,
  });

  final String id;
  final String name;
  final int colorIndex;
}

class NoteItem {
  const NoteItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String subjectId;
  final String title;
  final String body;
  final DateTime updatedAt;

  NoteItem copyWith({
    String? subjectId,
    String? title,
    String? body,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String formattedLastEdited([DateTime? now]) {
    final Duration diff = (now ?? DateTime.now()).difference(updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
