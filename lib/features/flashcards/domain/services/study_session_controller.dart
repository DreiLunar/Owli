import '../models/flashcard.dart';
import '../models/study_progress.dart';

class StudySessionController {
  final String deckId;
  final List<Flashcard> _cards;

  final Map<String, StudyResult> _results = {};

  int _currentIndex = 0;
  bool _isAnswerVisible = false;

  StudySessionController({required this.deckId, required List<Flashcard> cards})
    : _cards = List<Flashcard>.unmodifiable(cards) {
    if (_cards.isEmpty) {
      throw ArgumentError('Cannot start a session with no flashcards.');
    }

    if (_cards.any((card) => card.deckId != deckId)) {
      throw ArgumentError('All flashcards must belong to the selected deck.');
    }

    final uniqueIds = _cards.map((card) => card.id).toSet();

    if (uniqueIds.length != _cards.length) {
      throw ArgumentError('A study session cannot contain duplicate card IDs.');
    }
  }

  // SESSION INFORMATION

  int get totalCards => _cards.length;

  int get reviewedCards => _results.length;

  int get remainingCards => totalCards - reviewedCards;

  bool get isCompleted => reviewedCards == totalCards;

  bool get isAnswerVisible => _isAnswerVisible;

  int? get currentCardNumber => isCompleted ? null : _currentIndex + 1;

  Flashcard? get currentCard => isCompleted ? null : _cards[_currentIndex];

  // LEARNING OUTCOMES

  int get gotItCount =>
      _results.values.where((result) => result == StudyResult.gotIt).length;

  int get stillLearningCount => _results.values
      .where((result) => result == StudyResult.stillLearning)
      .length;

  Map<String, StudyResult> get results =>
      Map<String, StudyResult>.unmodifiable(_results);

  List<Flashcard> get stillLearningCards => List<Flashcard>.unmodifiable(
    _cards.where((card) => _results[card.id] == StudyResult.stillLearning),
  );

  // PROGRESS CALCULATIONS

  double get progress => reviewedCards / totalCards;

  double get completionPercentage => progress * 100;

  double get recallPercentage {
    if (reviewedCards == 0) {
      return 0;
    }

    return (gotItCount / reviewedCards) * 100;
  }

  // ANSWER VISIBILITY

  void toggleAnswer() {
    if (isCompleted) {
      throw StateError('Study session is already completed.');
    }

    _isAnswerVisible = !_isAnswerVisible;
  }

  // RATE CURRENT FLASHCARD

  void rateCurrentCard({required String cardId, required StudyResult result}) {
    if (isCompleted) {
      throw StateError('Study session is already completed.');
    }

    final card = currentCard!;

    if (card.id != cardId) {
      throw StateError('This is not the current flashcard.');
    }

    if (!_isAnswerVisible) {
      throw StateError('Reveal the answer before rating the flashcard.');
    }

    if (_results.containsKey(card.id)) {
      throw StateError('This flashcard is already rated.');
    }

    _results[card.id] = result;

    _currentIndex++;
    _isAnswerVisible = false;
  }

  // RESTART SESSION

  void restart() {
    _results.clear();
    _currentIndex = 0;
    _isAnswerVisible = false;
  }
}
