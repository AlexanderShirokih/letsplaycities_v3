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

/// Replaces some invalid chars in the [city]
String formatCity(String city) {
  final s = city.trim().toLowerCase();
  final replaced = s.replaceAll("ё", "е");
  final sb = StringBuffer();
  var prev = 0;

  final dash = '-'.codeUnitAt(0);

  for (var element in replaced.codeUnits) {
    if (!(element == dash && prev == dash)) {
      sb.write(element);
    }
    prev = element;
  }
  return sb.toString();
}

/// Converts [time] in millis to string representation
String timeFormat(int time) {
  var t = time;
  var ret = "";
  var min = t ~/ 60000;
  t -= min * 60000;
  t ~/= 1000;
  if (min > 0) {
    ret = min.toString() + "мин ";
  }
  ret += t.toString() + "сек";
  return ret;
}
