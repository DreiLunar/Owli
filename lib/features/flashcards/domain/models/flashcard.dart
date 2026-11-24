class Flashcard {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String? sourceNoteId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.sourceNoteId,
    required this.createdAt,
    required this.updatedAt,
  });
}
