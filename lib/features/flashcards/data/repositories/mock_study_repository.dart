import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import '../../domain/models/study_progress.dart';
import '../../domain/repositories/study_repository.dart';
import '../mock/mock_study_store.dart';

class MockStudyRepository implements StudyRepository {
  final MockStudyStore _store;

  @override
  final String userId;

  MockStudyRepository({MockStudyStore? store, String userId = 'mock_user'})
    : _store = store ?? MockStudyStore(),
      userId = userId.trim() {
    if (this.userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }
  }

  // OWNERSHIP VALIDATION
  Deck _requireOwnedDeck(String deckId) {
    for (final deck in _store.decks) {
      if (deck.id == deckId && deck.ownerId == userId) {
        return deck;
      }
    }
    throw StateError('Deck not found or access denied.');
  }

  // DECK MANAGEMENT
  @override
  Future<List<Deck>> fetchDecks() async {
    return List<Deck>.unmodifiable(
      _store.decks.where((deck) => deck.ownerId == userId),
    );
  }

  @override
  Future<void> createDeck({
    required String subjectId,
    required String title,
    String description = '',
  }) async {
    final cleanSubjectId = subjectId.trim();
    if (cleanSubjectId.isEmpty) {
      throw ArgumentError('Subject ID cannot be empty.');
    }
    _store.createDeck(
      title: title,
      description: description,
      ownerId: userId,
      subjectId: cleanSubjectId,
    );
  }

  @override
  Future<void> updateDeck({
    required String deckId,
    required String title,
    String description = '',
  }) async {
    _requireOwnedDeck(deckId);
    _store.updateDeck(deckId: deckId, title: title, description: description);
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    _requireOwnedDeck(deckId);
    _store.deleteDeck(deckId);
  }

  // FLASHCARD MANAGEMENT
  @override
  Future<List<Flashcard>> fetchFlashcards({required String deckId}) async {
    _requireOwnedDeck(deckId);
    return _store.cardsForDeck(deckId);
  }

  @override
  Future<void> createFlashcard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    _requireOwnedDeck(deckId);
    _store.createFlashcard(deckId: deckId, front: front, back: back);
  }

  @override
  Future<void> updateFlashcard({
    required String deckId,
    required String cardId,
    required String front,
    required String back,
  }) async {
    _requireOwnedDeck(deckId);
    _store.updateFlashcard(
      deckId: deckId,
      cardId: cardId,
      front: front,
      back: back,
    );
  }

  @override
  Future<void> deleteFlashcard({
    required String deckId,
    required String cardId,
  }) async {
    _requireOwnedDeck(deckId);
    _store.deleteFlashcard(deckId: deckId, cardId: cardId);
  }

  // STUDY PROGRESS
  @override
  Future<List<StudyProgress>> fetchProgress({required String deckId}) async {
    _requireOwnedDeck(deckId);
    return _store.progressForDeck(userId: userId, deckId: deckId);
  }

  @override
  Future<void> saveSessionResults({
    required String deckId,
    required Map<String, StudyResult> results,
    Map<String, Flashcard>? expectedCards,
  }) async {
    _requireOwnedDeck(deckId);

    if (expectedCards != null) {
      if (expectedCards.length != results.length) {
        throw ArgumentError('Session snapshot mismatch.');
      }

      final currentCards = {
        for (final card in _store.cardsForDeck(deckId)) card.id: card,
      };

      for (final cardId in results.keys) {
        final expected = expectedCards[cardId];
        final current = currentCards[cardId];

        if (expected == null ||
            expected.id != cardId ||
            expected.deckId != deckId ||
            current == null ||
            current.front != expected.front ||
            current.back != expected.back) {
          throw StateError('Flashcard content changed during study.');
        }
      }
    }

    _store.saveSessionResults(userId: userId, deckId: deckId, results: results);
  }

  @override
  Future<List<Flashcard>> fetchCardsNeedingReview({
    required String deckId,
  }) async {
    _requireOwnedDeck(deckId);
    return _store.cardsNeedingReview(userId: userId, deckId: deckId);
  }
}
