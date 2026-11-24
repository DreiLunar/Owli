enum StudyResult { gotIt, stillLearning }

class StudyProgress {
  final String userId;
  final String cardId;
  final String deckId;
  final StudyResult lastResult;
  final DateTime lastReviewedAt;
  final DateTime? nextReviewAt;

  const StudyProgress({
    required this.userId,
    required this.cardId,
    required this.deckId,
    required this.lastResult,
    required this.lastReviewedAt,
    this.nextReviewAt,
  });
}
