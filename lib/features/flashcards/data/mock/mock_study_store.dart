import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import 'mock_decks.dart';

class MockStudyStore {
  final List<Deck> _decks = List<Deck>.of(mockDecks);

  final List<Flashcard> _flashcards = List<Flashcard>.of(mockFlashcards);

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

    return updatedCard;
  }

  // DELETE FLASHCARD
  void deleteFlashcard({required String deckId, required String cardId}) {
    final index = _findFlashcardIndex(deckId: deckId, cardId: cardId);

    _flashcards.removeAt(index);
  }
}
