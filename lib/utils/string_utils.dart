/// Utilities functions for formatting strings.

extension FormatExtension on String {
  /// Formats '%1$ %2$'.format(['Hello', 'world']) to 'Hello world'
  String format(List<Object> params) {
    var result = this;
    for (var i = 1; i < params.length + 1; i++) {
      result = result.replaceAll('%$i\$', params[i - 1].toString());
    }
    return result;
  }
}

extension CapitalizeExtension on String {
  /// Converts the string to title case.
  /// For ex.: 'lower-case string' will be converted to 'Lower-Case String'
  String toTitleCase() {
    final buffer = StringBuffer();

    for (var i = 0; i < length; i++) {
      var c = this[i];
      if (i == 0 || this[i - 1] == '-' || this[i - 1] == ' ') {
        c = c.toUpperCase();
      }
      buffer.write(c);
    }

    return buffer.toString();
  }
}

/// Returns plural form depending of [count] value.
/// [count]:
///   1 - returns variant[0],
///   2 - returns variant[1],
///   other - returns variant[2]
String getPluralForm(List<String> variants, int count) {
  switch (count) {
    case 1:
      return variants[0];
    case 2:
      return variants[1];
    default:
      return variants[2];
  }
}

String findLastSuitableChar(String word) =>
    word.isEmpty ? '' : word[indexOfLastSuitableChar(word)];

/// Finds the last index in [city] of char which is not ends at bad letters or returns empty string
int indexOfLastSuitableChar(String city) {
  final c = city.lastIndexOf(RegExp(r'[^ь^ъ^ы^ё]'));
  return (c == -1) ? 0 : c;
}

/// Replaces some invalid chars in the [city]
String formatCity(String city) {
  final s = city.trim().toLowerCase();
  final replaced = s.replaceAll('ё', 'е');
  final sb = StringBuffer();
  var prev = 0;

  final dash = '-'.codeUnitAt(0);

  for (var element in replaced.runes) {
    if (!(element == dash && prev == dash)) {
      sb.writeCharCode(element);
    }
    prev = element;
  }
  return sb.toString();
}

/// Converts [time] in millis to string representation
String formatTime(int time) {
  var t = time;
  var ret = '';
  var min = t ~/ 60;
  t -= min * 60;
  if (min > 0) {
    ret = min.toString() + 'мин ';
  }
  ret += t.toString() + 'сек';
  return ret;
}
