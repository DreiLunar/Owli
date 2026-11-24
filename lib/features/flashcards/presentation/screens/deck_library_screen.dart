import 'package:material_ui/material_ui.dart';

import '../../data/mock/mock_decks.dart';
import '../../domain/models/deck.dart';
import 'create_deck_screen.dart';

class DeckLibraryScreen extends StatefulWidget {
  const DeckLibraryScreen({super.key});

  @override
  State<DeckLibraryScreen> createState() => _DeckLibraryScreenState();
}

class _DeckLibraryScreenState extends State<DeckLibraryScreen> {
  String _searchQuery = '';

  final _searchController = TextEditingController();

  final List<MockDeckEntry> _decks = List<MockDeckEntry>.of(mockDecks);

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createDeck() async {
    final draft = await Navigator.of(context).push<DeckDraft>(
      MaterialPageRoute(builder: (context) => const CreateDeckScreen()),
    );

    if (!mounted || draft == null) {
      return;
    }

    final now = DateTime.now();

    final newDeck = Deck(
      id: 'deck_${now.microsecondsSinceEpoch}',
      ownerId: 'mock_user',
      title: draft.title,
      description: draft.description,
      createdAt: now,
      updatedAt: now,
    );

    _searchController.clear();

    setState(() {
      _searchQuery = '';

      _decks.insert(0, MockDeckEntry(deck: newDeck, cardCount: 0));
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deck created successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    final filteredDecks = _decks.where((entry) {
      final query = _searchQuery.trim().toLowerCase();

      return entry.deck.title.toLowerCase().contains(query) ||
          entry.deck.description.toLowerCase().contains(query);
    }).toList();

    final totalCards = _decks.fold<int>(
      0,
      (total, entry) => total + entry.cardCount,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDeck,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Deck'),
      ),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Study',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            const Text(
              'Build your knowledge, one card at a time.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Library summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lavenderColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR LIBRARY',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_decks.length} Decks',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C1D95),
                    ),
                  ),
                  Text(
                    '$totalCards flashcards to explore',
                    style: const TextStyle(color: primaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search your decks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Deck list heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Decks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${filteredDecks.length} decks',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Deck list or empty state
            if (filteredDecks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No decks found'),
                  ],
                ),
              )
            else
              ...filteredDecks.map(_buildDeckCard),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(MockDeckEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E2F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lavenderColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.style_outlined, color: primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.deck.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.deck.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.cardCount} cards',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
