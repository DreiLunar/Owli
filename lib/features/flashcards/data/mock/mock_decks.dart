import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';

final _mockDate = DateTime(2026, 11, 24);

final mockDecks = <Deck>[
  Deck(
    id: 'deck_001',
    ownerId: 'mock_user',
    title: 'Automata Theory',
    description: 'Finite automata and formal languages',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Deck(
    id: 'deck_002',
    ownerId: 'mock_user',
    title: 'Mobile Computing',
    description: 'Mobile networks and architectures',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Deck(
    id: 'deck_003',
    ownerId: 'mock_user',
    title: 'Data Analysis',
    description: 'Statistics and data interpretation',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
];

final mockFlashcards = <Flashcard>[
  Flashcard(
    id: 'card_001',
    deckId: 'deck_001',
    front: 'What is a DFA?',
    back: 'A deterministic finite automaton.',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Flashcard(
    id: 'card_002',
    deckId: 'deck_001',
    front: 'What is an alphabet?',
    back: 'A finite set of symbols.',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Flashcard(
    id: 'card_003',
    deckId: 'deck_002',
    front: 'What is mobile computing?',
    back: 'Computing using portable devices.',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Flashcard(
    id: 'card_004',
    deckId: 'deck_002',
    front: 'What is LAN?',
    back: 'Local Area Network.',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Flashcard(
    id: 'card_005',
    deckId: 'deck_003',
    front: 'What is the mean?',
    back: 'The sum of values divided by their count.',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
  Flashcard(
    id: 'card_006',
    deckId: 'deck_003',
    front: 'What is the median?',
    back:
        'The middle value of an ordered dataset, '
        'or the mean of the two middle values.',
    createdAt: _mockDate,
    updatedAt: _mockDate,
  ),
];
