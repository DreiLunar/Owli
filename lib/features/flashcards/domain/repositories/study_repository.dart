import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/study_progress.dart';

abstract interface class StudyRepository {
  String get userId;

  Future<List<Deck>> fetchDecks();

  Future<void> createDeck({
    required String subjectId,
    required String title,
    String description = '',
  });

  Future<void> updateDeck({
    required String deckId,
    required String title,
    String description = '',
  });

  Future<void> deleteDeck(String deckId);

  Future<List<Flashcard>> fetchFlashcards({required String deckId});

  Future<void> createFlashcard({
    required String deckId,
    required String front,
    required String back,
  });

  Future<void> updateFlashcard({
    required String deckId,
    required String cardId,
    required String front,
    required String back,
  });

  Future<void> deleteFlashcard({
    required String deckId,
    required String cardId,
  });

  Future<List<StudyProgress>> fetchProgress({required String deckId});

  Future<void> saveSessionResults({
    required String deckId,
    required Map<String, StudyResult> results,
    Map<String, Flashcard>? expectedCards,
  });

  Future<List<Flashcard>> fetchCardsNeedingReview({required String deckId});
}
