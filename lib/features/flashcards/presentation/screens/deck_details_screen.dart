import 'package:material_ui/material_ui.dart';

import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';

class DeckDetailsScreen extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> flashcards;

  const DeckDetailsScreen({
    super.key,
    required this.deck,
    required this.flashcards,
  });

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Deck Details'),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
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
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUESTION',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
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
