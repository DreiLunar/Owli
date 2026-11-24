import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mock/mock_study_store.dart';

void main() {
  late MockStudyStore store;

  setUp(() {
    store = MockStudyStore();
  });

  group('Deck CRUD', () {
    test('Initial mock data is correct', () {
      expect(store.decks.length, 3);
      expect(store.totalCardCount, 6);
    });

    test('Create a new deck', () {
      final deck = store.createDeck(title: 'Web Systems');

      expect(store.decks.length, 4);
      expect(deck.title, 'Web Systems');
      expect(store.cardCountForDeck(deck.id), 0);
    });

    test('Reject an empty deck title', () {
      expect(() => store.createDeck(title: '   '), throwsArgumentError);
    });

    test('Update deck while preserving identity', () {
      final original = store.decks.first;

      final updated = store.updateDeck(
        deckId: original.id,
        title: 'Updated Automata',
        description: 'Updated description',
      );

      expect(updated.id, original.id);
      expect(updated.ownerId, original.ownerId);
      expect(updated.subjectId, original.subjectId);
      expect(updated.createdAt, original.createdAt);
      expect(updated.title, 'Updated Automata');
      expect(store.cardCountForDeck(updated.id), 2);
    });

    test('Reject an invalid updated title', () {
      final deck = store.decks.first;

      expect(
        () => store.updateDeck(deckId: deck.id, title: '   '),
        throwsArgumentError,
      );

      expect(store.decks.first.title, deck.title);
    });

    test('Delete deck and associated flashcards', () {
      final deck = store.decks.first;

      store.deleteDeck(deck.id);

      expect(store.decks.length, 2);
      expect(store.totalCardCount, 4);
      expect(store.cardsForDeck(deck.id), isEmpty);

      expect(store.cardCountForDeck('deck_002'), 2);
    });

    test('Deleting an unknown deck throws an error', () {
      expect(() => store.deleteDeck('invalid_id'), throwsStateError);

      expect(store.decks.length, 3);
      expect(store.totalCardCount, 6);
    });
  });
}
