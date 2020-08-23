/// The result of word processing
enum WordResult {
  /// Received from the server
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
}
