import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import 'mock_decks.dart';

class MockStudyStore {
  final List<Deck> _decks = List<Deck>.of(mockDecks);

  final List<Flashcard> _flashcards = List<Flashcard>.of(mockFlashcards);

  int _nextDeckId = 1;

  List<Deck> get decks => List<Deck>.unmodifiable(_decks);

  int get totalCardCount => _flashcards.length;

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
}
