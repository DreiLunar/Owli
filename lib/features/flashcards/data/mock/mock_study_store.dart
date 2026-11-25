import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import '../../domain/models/study_progress.dart';
import 'mock_decks.dart';

class MockStudyStore {
  final List<Deck> _decks = List<Deck>.of(mockDecks);

  final List<Flashcard> _flashcards = List<Flashcard>.of(mockFlashcards);

  final Map<(String, String, String), StudyProgress> _studyProgress = {};

  int _nextDeckId = 1;
  int _nextCardId = 1;

  List<Deck> get decks => List<Deck>.unmodifiable(_decks);

  int get totalCardCount => _flashcards.length;

  // READ FLASHCARDS
  List<Flashcard> cardsForDeck(String deckId) {
    return List<Flashcard>.unmodifiable(
      _flashcards.where((card) => card.deckId == deckId),
    );
  }

  int cardCountForDeck(String deckId) {
    return _flashcards.where((card) => card.deckId == deckId).length;
  }

  Deck createDeck({required String title, String description = ''}) {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Deck title cannot be empty.');
    }

    final now = DateTime.now();

    final deck = Deck(
      id: 'mock_deck_${_nextDeckId++}',
      ownerId: 'mock_user',
      title: cleanTitle,
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );

    _decks.insert(0, deck);

    return deck;
  }

  Deck updateDeck({
    required String deckId,
    required String title,
    String description = '',
  }) {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Deck title cannot be empty.');
    }

    final index = _decks.indexWhere((deck) => deck.id == deckId);

    if (index == -1) {
      throw StateError('Deck not found.');
    }

    final existingDeck = _decks[index];

    final updatedDeck = Deck(
      id: existingDeck.id,
      ownerId: existingDeck.ownerId,
      subjectId: existingDeck.subjectId,
      title: cleanTitle,
      description: description.trim(),
      createdAt: existingDeck.createdAt,
      updatedAt: DateTime.now(),
    );

    _decks[index] = updatedDeck;

    return updatedDeck;
  }

  void deleteDeck(String deckId) {
    final index = _decks.indexWhere((deck) => deck.id == deckId);

    if (index == -1) {
      throw StateError('Deck not found.');
    }

    _studyProgress.removeWhere((key, progress) => progress.deckId == deckId);

    _flashcards.removeWhere((card) => card.deckId == deckId);

    _decks.removeAt(index);
  }

  Flashcard createFlashcard({
    required String deckId,
    required String front,
    required String back,
  }) {
    final cleanFront = front.trim();
    final cleanBack = back.trim();

    if (cleanFront.isEmpty) {
      throw ArgumentError('Flashcard question cannot be empty.');
    }

    if (cleanBack.isEmpty) {
      throw ArgumentError('Flashcard answer cannot be empty.');
    }

    final deckExists = _decks.any((deck) => deck.id == deckId);

    if (!deckExists) {
      throw StateError('Deck not found.');
    }

    final now = DateTime.now();

    final flashcard = Flashcard(
      id: 'mock_card_${_nextCardId++}',
      deckId: deckId,
      front: cleanFront,
      back: cleanBack,
      createdAt: now,
      updatedAt: now,
    );

    _flashcards.add(flashcard);

    return flashcard;
  }

  int _findFlashcardIndex({required String deckId, required String cardId}) {
    final index = _flashcards.indexWhere(
      (card) => card.id == cardId && card.deckId == deckId,
    );

    if (index == -1) {
      throw StateError('Flashcard not found in this deck.');
    }

    return index;
  }

  // UPDATE FLASHCARD
  Flashcard updateFlashcard({
    required String deckId,
    required String cardId,
    required String front,
    required String back,
  }) {
    final cleanFront = front.trim();
    final cleanBack = back.trim();

    if (cleanFront.isEmpty) {
      throw ArgumentError('Flashcard question cannot be empty.');
    }

    if (cleanBack.isEmpty) {
      throw ArgumentError('Flashcard answer cannot be empty.');
    }

    final index = _findFlashcardIndex(deckId: deckId, cardId: cardId);

    final existingCard = _flashcards[index];

    final updatedCard = Flashcard(
      id: existingCard.id,
      deckId: existingCard.deckId,
      sourceNoteId: existingCard.sourceNoteId,
      front: cleanFront,
      back: cleanBack,
      createdAt: existingCard.createdAt,
      updatedAt: DateTime.now(),
    );

    _flashcards[index] = updatedCard;

    // Previous recall may no longer apply
    // when the learning content changes.
    if (existingCard.front != updatedCard.front ||
        existingCard.back != updatedCard.back) {
      _removeCardProgress(deckId: deckId, cardId: cardId);
    }

    return updatedCard;
  }

  // DELETE FLASHCARD
  void deleteFlashcard({required String deckId, required String cardId}) {
    final index = _findFlashcardIndex(deckId: deckId, cardId: cardId);

    _removeCardProgress(deckId: deckId, cardId: cardId);

    _flashcards.removeAt(index);
  }

  // SAVE COMPLETED SESSION RESULTS
  void saveSessionResults({
    required String userId,
    required String deckId,
    required Map<String, StudyResult> results,
    DateTime? reviewedAt,
  }) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    if (results.isEmpty) {
      throw ArgumentError('Session results cannot be empty.');
    }

    final deckExists = _decks.any((deck) => deck.id == deckId);

    if (!deckExists) {
      throw StateError('Deck not found.');
    }

    // Validate all cards before writing any progress.
    for (final cardId in results.keys) {
      _findFlashcardIndex(deckId: deckId, cardId: cardId);
    }

    final timestamp = reviewedAt ?? DateTime.now();

    for (final entry in results.entries) {
      final progress = StudyProgress(
        userId: userId,
        deckId: deckId,
        cardId: entry.key,
        lastResult: entry.value,
        lastReviewedAt: timestamp,
      );

      _studyProgress[(userId, deckId, entry.key)] = progress;
    }
  }

  // GET INDIVIDUAL CARD PROGRESS
  StudyProgress? progressForCard({
    required String userId,
    required String deckId,
    required String cardId,
  }) {
    return _studyProgress[(userId, deckId, cardId)];
  }

  // GET ALL PROGRESS FOR A USER'S DECK
  List<StudyProgress> progressForDeck({
    required String userId,
    required String deckId,
  }) {
    return List<StudyProgress>.unmodifiable(
      _studyProgress.values.where(
        (progress) => progress.userId == userId && progress.deckId == deckId,
      ),
    );
  }

  // GET CARDS THAT REQUIRE FURTHER REVIEW
  List<Flashcard> cardsNeedingReview({
    required String userId,
    required String deckId,
  }) {
    return List<Flashcard>.unmodifiable(
      _flashcards.where(
        (card) =>
            card.deckId == deckId &&
            progressForCard(
                  userId: userId,
                  deckId: deckId,
                  cardId: card.id,
                )?.lastResult ==
                StudyResult.stillLearning,
      ),
    );
  }

  // REMOVE PROGRESS ASSOCIATED WITH A CARD
  void _removeCardProgress({required String deckId, required String cardId}) {
    _studyProgress.removeWhere(
      (key, progress) => progress.deckId == deckId && progress.cardId == cardId,
    );
  }
}
