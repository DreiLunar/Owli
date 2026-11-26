import 'package:flutter_test/flutter_test.dart';

import 'package:owli/features/flashcards/data/mappers/study_progress_key.dart';

void main() {
  group('Study Progress Identity', () {
    // TEST 1
    test('Builds the expected deterministic ID', () {
      expect(
        StudyProgressKey.build(
          userId: 'user_001',
          deckId: 'deck_001',
          cardId: 'card_001',
        ),
        'user_001~deck_001~card_001',
      );
    });

    // TEST 2
    test('Repeated identity produces the same key', () {
      String build() => StudyProgressKey.build(
        userId: 'user_001',
        deckId: 'deck_001',
        cardId: 'card_001',
      );

      expect(build(), build());
    });

    // TEST 3
    test('Different users produce different keys', () {
      final first = StudyProgressKey.build(
        userId: 'user_a',
        deckId: 'deck_001',
        cardId: 'card_001',
      );

      final second = StudyProgressKey.build(
        userId: 'user_b',
        deckId: 'deck_001',
        cardId: 'card_001',
      );

      expect(first, isNot(second));
    });

    // TEST 4
    test('Different decks produce different keys', () {
      final first = StudyProgressKey.build(
        userId: 'user_001',
        deckId: 'deck_a',
        cardId: 'card_001',
      );

      final second = StudyProgressKey.build(
        userId: 'user_001',
        deckId: 'deck_b',
        cardId: 'card_001',
      );

      expect(first, isNot(second));
    });

    // TEST 5
    test('Different cards produce different keys', () {
      final first = StudyProgressKey.build(
        userId: 'user_001',
        deckId: 'deck_001',
        cardId: 'card_a',
      );

      final second = StudyProgressKey.build(
        userId: 'user_001',
        deckId: 'deck_001',
        cardId: 'card_b',
      );

      expect(first, isNot(second));
    });

    // TEST 6
    test('Rejects malformed identity components', () {
      final invalidIds = [
        '',
        ' ',
        'user~001',
        'user/001',
        'user.001',
        'user 001',
        'user\n',
        List.filled(129, 'a').join(),
      ];

      for (final invalid in invalidIds) {
        expect(
          () => StudyProgressKey.build(
            userId: invalid,
            deckId: 'deck_001',
            cardId: 'card_001',
          ),
          throwsArgumentError,
        );

        expect(
          () => StudyProgressKey.build(
            userId: 'user_001',
            deckId: invalid,
            cardId: 'card_001',
          ),
          throwsArgumentError,
        );

        expect(
          () => StudyProgressKey.build(
            userId: 'user_001',
            deckId: 'deck_001',
            cardId: invalid,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
