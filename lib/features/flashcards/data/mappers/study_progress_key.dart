class StudyProgressKey {
  StudyProgressKey._();

  static final _validPart = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static String _validate(String value) {
    final match = _validPart.firstMatch(value);

    if (match == null || match.group(0) != value) {
      throw ArgumentError('Invalid progress identity component.');
    }

    return value;
  }

  static String build({
    required String userId,
    required String deckId,
    required String cardId,
  }) {
    return [_validate(userId), _validate(deckId), _validate(cardId)].join('~');
  }
}
