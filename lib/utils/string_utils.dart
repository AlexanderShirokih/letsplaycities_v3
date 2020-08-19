/// Utilities functions for formatting strings.

extension CapitalizeExtension on String {
  /// Converts the string to title case.
  /// For ex.: "lower-case string" will be converted to "Lower-Case String"
  String toTitleCase() {
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      var c = this[i];
      if (i == 0 || this[i - 1] == '-' || this[i - 1] == ' ')
        c = c.toUpperCase();
      buffer.write(c);
    }

    return buffer.toString();
  }
}

/// Finds the last index in [city] of char which is not ends at bad letters or returns empty string
int indexOfLastSuitableChar(String city) {
  final c = city.lastIndexOf(RegExp(r"[^ь^ъ^ы^ё]"));
  return (c == -1) ? 0 : c;
}
