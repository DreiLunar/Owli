import '../../domain/models/deck.dart';

class MockDeckEntry {
  final Deck deck;
  final int cardCount;

  const MockDeckEntry({required this.deck, required this.cardCount});
}

final mockDecks = [
  MockDeckEntry(
    deck: Deck(
      id: 'deck_001',
      ownerId: 'mock_user',
      title: 'Automata Theory',
      description: 'Finite automata and formal languages',
      createdAt: DateTime(2026, 11, 24),
      updatedAt: DateTime(2026, 11, 24),
    ),
    cardCount: 24,
  ),
  MockDeckEntry(
    deck: Deck(
      id: 'deck_002',
      ownerId: 'mock_user',
      title: 'Mobile Computing',
      description: 'Mobile networks and architectures',
      createdAt: DateTime(2026, 11, 24),
      updatedAt: DateTime(2026, 11, 24),
    ),
    cardCount: 18,
  ),
  MockDeckEntry(
    deck: Deck(
      id: 'deck_003',
      ownerId: 'mock_user',
      title: 'Data Analysis',
      description: 'Statistics and data interpretation',
      createdAt: DateTime(2026, 11, 24),
      updatedAt: DateTime(2026, 11, 24),
    ),
    cardCount: 12,
  ),
];
