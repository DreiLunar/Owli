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

  group('Flashcard Creation', () {
    test('Create a flashcard in an existing deck', () {
      final deck = store.decks.first;

      final card = store.createFlashcard(
        deckId: deck.id,
        front: 'What is an NFA?',
        back: 'A nondeterministic finite automaton.',
      );

      expect(card.deckId, deck.id);
      expect(card.front, 'What is an NFA?');

      expect(card.back, 'A nondeterministic finite automaton.');

      expect(store.cardCountForDeck(deck.id), 3);
      expect(store.totalCardCount, 7);
    });

    test('Create a flashcard in a new deck', () {
      final deck = store.createDeck(title: 'Web Systems');

      final card = store.createFlashcard(
        deckId: deck.id,
        front: 'What is HTML?',
        back: 'HyperText Markup Language.',
      );

      expect(card.deckId, deck.id);
      expect(store.cardCountForDeck(deck.id), 1);
      expect(store.totalCardCount, 7);
    });

    test('Reject an empty question', () {
      expect(
        () => store.createFlashcard(
          deckId: 'deck_001',
          front: '   ',
          back: 'Answer',
        ),
        throwsArgumentError,
      );

      expect(store.totalCardCount, 6);
    });

    test('Reject an empty answer', () {
      expect(
        () => store.createFlashcard(
          deckId: 'deck_001',
          front: 'Question',
          back: '   ',
        ),
        throwsArgumentError,
      );

      expect(store.totalCardCount, 6);
    });

    test('Reject a nonexistent deck', () {
      expect(
        () => store.createFlashcard(
          deckId: 'invalid_deck',
          front: 'Question',
          back: 'Answer',
        ),
        throwsStateError,
      );

      expect(store.totalCardCount, 6);
    });

    test('Generate unique flashcard IDs', () {
      final first = store.createFlashcard(
        deckId: 'deck_001',
        front: 'Question 1',
        back: 'Answer 1',
      );

      final second = store.createFlashcard(
        deckId: 'deck_001',
        front: 'Question 2',
        back: 'Answer 2',
      );

      expect(first.id, isNot(second.id));
    });

    test('Trim question and answer whitespace', () {
      final card = store.createFlashcard(
        deckId: 'deck_001',
        front: '  Question  ',
        back: '  Answer  ',
      );

      expect(card.front, 'Question');
      expect(card.back, 'Answer');
    });

    test('Other decks remain unaffected', () {
      store.createFlashcard(
        deckId: 'deck_001',
        front: 'Question',
        back: 'Answer',
      );

      expect(store.cardCountForDeck('deck_001'), 3);
      expect(store.cardCountForDeck('deck_002'), 2);
      expect(store.cardCountForDeck('deck_003'), 2);
    });

    test('Deleting a deck removes newly added cards', () {
      store.createFlashcard(
        deckId: 'deck_001',
        front: 'Question',
        back: 'Answer',
      );

      store.deleteDeck('deck_001');

      expect(store.cardsForDeck('deck_001'), isEmpty);
      expect(store.totalCardCount, 4);
      expect(store.decks.length, 2);
    });
  });

  group('Flashcard Update and Delete', () {
    test('Update a flashcard while preserving identity', () {
      final original = store.cardsForDeck('deck_001').first;

      final updated = store.updateFlashcard(
        deckId: original.deckId,
        cardId: original.id,
        front: 'Updated question',
        back: 'Updated answer',
      );

      expect(updated.id, original.id);
      expect(updated.deckId, original.deckId);
      expect(updated.sourceNoteId, original.sourceNoteId);
      expect(updated.createdAt, original.createdAt);
      expect(updated.front, 'Updated question');
      expect(updated.back, 'Updated answer');
      expect(store.totalCardCount, 6);
      expect(store.cardCountForDeck('deck_001'), 2);

      final stored = store.cardsForDeck('deck_001').first;

      expect(stored.front, 'Updated question');
      expect(stored.back, 'Updated answer');
    });

    test('Reject an empty updated question', () {
      expect(
        () => store.updateFlashcard(
          deckId: 'deck_001',
          cardId: 'card_001',
          front: '   ',
          back: 'Valid answer',
        ),
        throwsArgumentError,
      );

      expect(store.cardsForDeck('deck_001').first.front, 'What is a DFA?');
    });

    test('Reject an empty updated answer', () {
      expect(
        () => store.updateFlashcard(
          deckId: 'deck_001',
          cardId: 'card_001',
          front: 'Valid question',
          back: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('Trim updated question and answer', () {
      final updated = store.updateFlashcard(
        deckId: 'deck_001',
        cardId: 'card_001',
        front: '  Updated question  ',
        back: '  Updated answer  ',
      );

      expect(updated.front, 'Updated question');
      expect(updated.back, 'Updated answer');
    });

    test('Reject updating an unknown flashcard', () {
      expect(
        () => store.updateFlashcard(
          deckId: 'deck_001',
          cardId: 'invalid_card',
          front: 'Question',
          back: 'Answer',
        ),
        throwsStateError,
      );
    });

    test('Reject updating a card from another deck', () {
      expect(
        () => store.updateFlashcard(
          deckId: 'deck_002',
          cardId: 'card_001',
          front: 'Question',
          back: 'Answer',
        ),
        throwsStateError,
      );
    });

    test('Delete an existing flashcard', () {
      store.deleteFlashcard(deckId: 'deck_001', cardId: 'card_001');

      expect(store.totalCardCount, 5);
      expect(store.cardCountForDeck('deck_001'), 1);
      expect(store.decks.length, 3);

      expect(
        store.cardsForDeck('deck_001').any((card) => card.id == 'card_001'),
        isFalse,
      );
    });

    test('Reject deleting an unknown flashcard', () {
      expect(
        () => store.deleteFlashcard(deckId: 'deck_001', cardId: 'invalid_card'),
        throwsStateError,
      );

      expect(store.totalCardCount, 6);
    });

    test('Reject deleting a card from another deck', () {
      expect(
        () => store.deleteFlashcard(deckId: 'deck_002', cardId: 'card_001'),
        throwsStateError,
      );

      expect(store.totalCardCount, 6);
    });

    test('Deleting all cards preserves the deck', () {
      store.deleteFlashcard(deckId: 'deck_001', cardId: 'card_001');

      store.deleteFlashcard(deckId: 'deck_001', cardId: 'card_002');

      expect(store.cardsForDeck('deck_001'), isEmpty);
      expect(store.decks.length, 3);
      expect(store.totalCardCount, 4);
      expect(store.cardCountForDeck('deck_002'), 2);
      expect(store.cardCountForDeck('deck_003'), 2);
    });

    test('Update and delete a newly created flashcard', () {
      final card = store.createFlashcard(
        deckId: 'deck_001',
        front: 'Original question',
        back: 'Original answer',
      );

      final updated = store.updateFlashcard(
        deckId: card.deckId,
        cardId: card.id,
        front: 'New question',
        back: 'New answer',
      );

      expect(updated.id, card.id);
      expect(updated.front, 'New question');

      store.deleteFlashcard(deckId: card.deckId, cardId: card.id);

      expect(store.totalCardCount, 6);
    });
  });
}
