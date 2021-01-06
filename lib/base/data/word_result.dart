/// The result of word processing
enum WordResult {
  /// Input word from another player received from the server
  RECEIVED,

  /// Accepted by server
  ACCEPTED,

  /// Error: The word was already used
  ALREADY,

  /// Error: There is no word in game database
  NO_WORD,

  /// Error: It's not a users turn
  WRONG_MOVE,

  /// Undefined state
  UNKNOWN,
}

extension WordResultExtensions on WordResult {
  /// Returns true if after this result move can be passed.
  bool isSuccessful() =>
      this == WordResult.RECEIVED || this == WordResult.ACCEPTED;

  static WordResult fromString(String s) {
    switch (s) {
      case 'RECEIVED':
        return WordResult.RECEIVED;
      case 'ACCEPTED':
        return WordResult.ACCEPTED;
      case 'ALREADY':
        return WordResult.ALREADY;
      case 'NO_WORD':
        return WordResult.NO_WORD;
      case 'WRONG_MOVE':
        return WordResult.WRONG_MOVE;
      case 'UNKNOWN':
        return WordResult.UNKNOWN;
      default:
        throw 'Unknown enum value: $s';
    }
  }
}
