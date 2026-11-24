import 'package:material_ui/material_ui.dart';

import '../../data/mock/mock_study_store.dart';
import '../../domain/models/deck.dart';

import 'create_deck_screen.dart';
import 'deck_details_screen.dart';

class DeckLibraryScreen extends StatefulWidget {
  const DeckLibraryScreen({super.key});

  @override
  State<DeckLibraryScreen> createState() => _DeckLibraryScreenState();
}

class _DeckLibraryScreenState extends State<DeckLibraryScreen> {
  final _store = MockStudyStore();

  final _searchController = TextEditingController();

  String _searchQuery = '';

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Create a deck through the store.
  Future<void> _createDeck() async {
    final draft = await Navigator.of(context).push<DeckDraft>(
      MaterialPageRoute(builder: (context) => const CreateDeckScreen()),
    );

    if (!mounted || draft == null) {
      return;
    }

    _searchController.clear();

    setState(() {
      _store.createDeck(title: draft.title, description: draft.description);

      _searchQuery = '';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deck created successfully!')));
  }

  // Open the selected deck and its flashcards.
  void _openDeck(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeckDetailsScreen(
          deck: deck,
          flashcards: _store.cardsForDeck(deck.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decks = _store.decks;

    final query = _searchQuery.trim().toLowerCase();

    final filteredDecks = decks.where((deck) {
      return deck.title.toLowerCase().contains(query) ||
          deck.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Study',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDeck,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Deck'),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            const Text('Build your knowledge, one card at a time.'),

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
                    '${decks.length} Decks',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C1D95),
                    ),
                  ),

                  Text(
                    '${_store.totalCardCount} '
                    'flashcards to explore',
                    style: const TextStyle(color: primaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Decks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('${filteredDecks.length} decks'),
              ],
            ),

            const SizedBox(height: 16),

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

  Widget _buildDeckCard(Deck deck) {
    final cardCount = _store.cardCountForDeck(deck.id);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        onTap: () => _openDeck(deck),

        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: lavenderColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.style_outlined, color: primaryColor),
        ),

        title: Text(
          deck.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deck.description.isNotEmpty) Text(deck.description),

            const SizedBox(height: 6),

            Text(
              '$cardCount cards',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
