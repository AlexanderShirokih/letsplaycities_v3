/// The result of word processing
enum WordResult {
  /// Input word from another player received from the server
  received('RECEIVED'),

  /// Accepted by server
  accepted('ACCEPTED'),

  /// Error: The word was already used
  already('ALREADY'),

  /// Error: There is no word in game database
  noWord('NO_WORD'),

  /// Error: It's not a users turn
  wrongMove('WRONG_MOVE'),

  /// Error: The word starts with a letter other than the last suitable one
  wrongLetter('WRONG_LETTER'),

  /// Undefined state
  unknown('UNKNOWN');

  const WordResult(this.wireName);

  /// Name of the result in the 'word' message
  final String wireName;

  /// Returns true if after this result move can be passed.
  bool isSuccessful() =>
      this == WordResult.received || this == WordResult.accepted;

  /// Returns the result named [s] by its [wireName].
  /// Throws a [String] when there is no such result.
  static WordResult fromString(String s) {
    for (final result in values) {
      if (result.wireName == s) {
        return result;
      }
    }
    throw 'Unknown enum value: $s';
  }
}
