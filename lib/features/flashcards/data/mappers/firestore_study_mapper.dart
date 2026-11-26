import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import '../../domain/models/study_progress.dart';

class FirestoreStudyMapper {
  FirestoreStudyMapper._();

  static String _nonEmptyString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$field must be a non-empty string.');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> data, String field) {
    return _nonEmptyString(data[field], field);
  }

  static String? _optionalString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value == null) return null;
    return _nonEmptyString(value, field);
  }

  static String _description(Map<String, dynamic> data) {
    final value = data['description'];
    if (value == null) return '';
    if (value is! String) {
      throw const FormatException('description must be a string.');
    }
    return value;
  }

  static DateTime _requiredTimestamp(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! Timestamp) {
      throw FormatException(
        '$field must contain a resolved Firestore Timestamp.',
      );
    }
    return value.toDate().toUtc();
  }

  static DateTime? _optionalTimestamp(Map<String, dynamic> data, String field) {
    if (data[field] == null) return null;
    return _requiredTimestamp(data, field);
  }

  static String encodeStudyResult(StudyResult result) {
    return switch (result) {
      StudyResult.gotIt => 'gotIt',
      StudyResult.stillLearning => 'stillLearning',
    };
  }

  static StudyResult decodeStudyResult(Object? value) {
    return switch (value) {
      'gotIt' => StudyResult.gotIt,
      'stillLearning' => StudyResult.stillLearning,
      _ => throw const FormatException('Invalid study result.'),
    };
  }

  static Deck deckFromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    if (data.containsKey('deleting') && data['deleting'] is! bool) {
      throw const FormatException('deleting must be a boolean.');
    }

    return Deck(
      id: _nonEmptyString(id, 'deckId'),
      ownerId: _requiredString(data, 'ownerId'),
      subjectId: _optionalString(data, 'subjectId'),
      title: _requiredString(data, 'title'),
      description: _description(data),
      createdAt: _requiredTimestamp(data, 'createdAt'),
      updatedAt: _requiredTimestamp(data, 'updatedAt'),
      isDeleting: data['deleting'] == true,
    );
  }

  static Map<String, dynamic> deckToMap(Deck deck) {
    return {
      'ownerId': deck.ownerId,
      'subjectId': deck.subjectId,
      'title': deck.title,
      'description': deck.description,
      'createdAt': Timestamp.fromDate(deck.createdAt),
      'updatedAt': Timestamp.fromDate(deck.updatedAt),
      if (deck.isDeleting) 'deleting': true,
    };
  }

  static Flashcard flashcardFromMap({
    required String id,
    required String deckId,
    required Map<String, dynamic> data,
  }) {
    final storedDeckId = _requiredString(data, 'deckId');
    if (storedDeckId != deckId) {
      throw const FormatException(
        'Flashcard deck ID does not match its parent deck.',
      );
    }
    return Flashcard(
      id: _nonEmptyString(id, 'cardId'),
      deckId: storedDeckId,
      front: _requiredString(data, 'front'),
      back: _requiredString(data, 'back'),
      sourceNoteId: _optionalString(data, 'sourceNoteId'),
      createdAt: _requiredTimestamp(data, 'createdAt'),
      updatedAt: _requiredTimestamp(data, 'updatedAt'),
    );
  }

  static Map<String, dynamic> flashcardToMap(Flashcard card) {
    return {
      'deckId': card.deckId,
      'front': card.front,
      'back': card.back,
      'sourceNoteId': card.sourceNoteId,
      'createdAt': Timestamp.fromDate(card.createdAt),
      'updatedAt': Timestamp.fromDate(card.updatedAt),
    };
  }

  static StudyProgress progressFromMap({
    required String expectedUserId,
    required String expectedDeckId,
    required Map<String, dynamic> data,
  }) {
    final userId = _requiredString(data, 'userId');
    final deckId = _requiredString(data, 'deckId');
    if (userId != expectedUserId) {
      throw const FormatException(
        'Progress user ID does not match the expected user.',
      );
    }
    if (deckId != expectedDeckId) {
      throw const FormatException(
        'Progress deck ID does not match the expected deck.',
      );
    }
    return StudyProgress(
      userId: userId,
      deckId: deckId,
      cardId: _requiredString(data, 'cardId'),
      lastResult: decodeStudyResult(data['lastResult']),
      lastReviewedAt: _requiredTimestamp(data, 'lastReviewedAt'),
      nextReviewAt: _optionalTimestamp(data, 'nextReviewAt'),
    );
  }

  static Map<String, dynamic> progressToMap(StudyProgress progress) {
    return {
      'userId': progress.userId,
      'deckId': progress.deckId,
      'cardId': progress.cardId,
      'lastResult': encodeStudyResult(progress.lastResult),
      'lastReviewedAt': Timestamp.fromDate(progress.lastReviewedAt),
      'nextReviewAt': progress.nextReviewAt == null
          ? null
          : Timestamp.fromDate(progress.nextReviewAt!),
    };
  }
}
