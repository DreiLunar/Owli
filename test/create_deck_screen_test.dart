import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:owli/features/decks/data/deck_providers.dart';
import 'package:owli/features/decks/data/deck_repository.dart';
import 'package:owli/features/flashcards/presentation/create_deck_screen.dart';

class _FakeDeckRepository implements DeckRepository {
  @override
  Future<void> createDeck({
    required String subjectId,
    required String title,
    String description = '',
  }) async {}

  @override
  Future<void> deleteDeck(String deckId) async {}

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyDecks() =>
      const Stream.empty();
}

void main() {
  testWidgets('keeps the root create screen open after saving', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckRepositoryProvider.overrideWithValue(_FakeDeckRepository()),
        ],
        child: const MaterialApp(
          home: CreateDeckScreen(subjectId: 'test-subject'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Physics');
    await tester.tap(find.text('Create deck'));
    await tester.pumpAndSettle();

    expect(find.text('New deck'), findsOneWidget);
    expect(find.text('Deck created successfully.'), findsOneWidget);
  });
}
