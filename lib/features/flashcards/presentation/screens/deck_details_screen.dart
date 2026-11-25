import 'package:material_ui/material_ui.dart';

import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import '../../data/mock/mock_study_store.dart';
import 'create_deck_screen.dart';
import 'create_flashcard_screen.dart';

class DeckDetailsScreen extends StatefulWidget {
  final Deck deck;
  final MockStudyStore store;

  const DeckDetailsScreen({super.key, required this.deck, required this.store});

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen> {
  late Deck deck;

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  List<Flashcard> get flashcards => widget.store.cardsForDeck(deck.id);

  @override
  void initState() {
    super.initState();
    deck = widget.deck;
  }

  // EDIT DECK
  Future<void> _editDeck() async {
    final draft = await Navigator.of(context).push<DeckDraft>(
      MaterialPageRoute(
        builder: (context) => CreateDeckScreen(initialDeck: deck),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    final updatedDeck = widget.store.updateDeck(
      deckId: deck.id,
      title: draft.title,
      description: draft.description,
    );

    setState(() {
      deck = updatedDeck;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deck updated successfully!')));
  }

  // DELETE DECK
  Future<void> _deleteDeck() async {
    final cardCount = flashcards.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete deck?'),
          content: Text(
            'This will delete "${deck.title}" '
            'and its $cardCount flashcards. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    widget.store.deleteDeck(deck.id);

    Navigator.of(context).pop();
  }

  // ADD FLASHCARD
  Future<void> _addFlashcard() async {
    final draft = await Navigator.of(context).push<FlashcardDraft>(
      MaterialPageRoute(
        builder: (context) => CreateFlashcardScreen(deckTitle: deck.title),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      widget.store.createFlashcard(
        deckId: deck.id,
        front: draft.front,
        back: draft.back,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flashcard added successfully!')),
    );
  }

  Future<void> _editFlashcard(Flashcard card) async {
    final draft = await Navigator.of(context).push<FlashcardDraft>(
      MaterialPageRoute(
        builder: (context) =>
            CreateFlashcardScreen(deckTitle: deck.title, initialCard: card),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      widget.store.updateFlashcard(
        deckId: deck.id,
        cardId: card.id,
        front: draft.front,
        back: draft.back,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flashcard updated successfully!')),
    );
  }

  Future<void> _deleteFlashcard(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete flashcard?'),

          content: Text(
            'Are you sure you want to delete '
            'this flashcard?\n\n'
            '${card.front}\n\n'
            'This action cannot be undone.',
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      widget.store.deleteFlashcard(deckId: deck.id, cardId: card.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flashcard deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // Add flashcard button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFlashcard,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Flashcard'),
      ),

      appBar: AppBar(
        title: const Text('Deck Details'),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Edit deck',
            onPressed: _editDeck,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete deck',
            onPressed: _deleteDeck,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            // Deck information
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lavenderColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.style_outlined,
                    color: primaryColor,
                    size: 36,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    deck.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (deck.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(deck.description),
                  ],

                  const SizedBox(height: 16),

                  Text(
                    '${flashcards.length} flashcards',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Flashcards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Empty state
            if (flashcards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.style_outlined, size: 56, color: Colors.grey),

                    SizedBox(height: 16),

                    Text(
                      'No flashcards yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Your flashcards will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...flashcards.map(_buildFlashcard),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return Card(
      key: ValueKey(card.id),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Question label and action buttons
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'QUESTION',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Edit flashcard',
                  onPressed: () => _editFlashcard(card),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                ),

                IconButton(
                  tooltip: 'Delete flashcard',
                  onPressed: () => _deleteFlashcard(card),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              card.front,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const Divider(height: 24),

            const Text(
              'ANSWER',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(card.back),
          ],
        ),
      ),
    );
  }
}
