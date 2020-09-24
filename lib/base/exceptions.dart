/// Exception thrown when game dictionary error happens during parsing
class DictionaryException implements Exception {
  final String message;
  final int line;

  const DictionaryException(this.message, this.line);

  @override
  String toString() =>
      'Error during dictionary parsing: $message; at dictionary line index=$line';
}
