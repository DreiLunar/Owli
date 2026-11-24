class Deck {
  final String id;
  final String ownerId;
  final String? subjectId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Deck({
    required this.id,
    required this.ownerId,
    this.subjectId,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });
}
