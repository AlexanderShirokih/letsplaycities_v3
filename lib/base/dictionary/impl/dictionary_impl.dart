import 'dart:math';

import 'package:lets_play_cities/base/dictionary/city_properties.dart';

import '../dictionary.dart';

/// Dictionary database implementation based on [Map].
/// Where map key is a city name, value is [CityProperties] describing this city.
class DictionaryServiceImpl extends DictionaryService {
  final Random _random = Random();

  final Map<String, CityProperties> _data;

  DictionaryServiceImpl(this._data);

  @override
  Map<String, CityProperties> getAll() => Map.unmodifiable(_data);

  @override
  Future<String> getRandomWordByDifficulty(
      String firstChar, int difficulty) async {
    final filtered = _data.entries
        .where((e) => e.key.startsWith(firstChar))
        .where((e) =>
            !e.value.used &&
            e.value.countryCode != 0 &&
            e.value.difficulty <= difficulty)
        .toList(growable: false);

    if (filtered.length == 0) return "";

    final index = _random.nextInt(filtered.length);
    return index >= filtered.length ? "" : filtered[index].key;
  }

  @override
  int getCountryCode(String city) => _data[city]?.countryCode ?? 0;

  @override
  void markUsed(String city) {
    _data[city]?.markUsed();
  }

  @override
  void clear() => _data.clear();

  @override
  void reset() {
    for (final prop in _data.values) prop.reset();
  }

  @override
  Future<Set<String>> getCorrectionVariants(String city) async {
    final list = _edits(city);
    final List<String> candidates = [];

    for (final s in list) {
      // Max 3 words
      if (candidates.length == 3) break;
      if (_canUse(s)) candidates.add(s);
    }

    if (candidates.isNotEmpty) return candidates.toSet();

    for (final s in list)
      for (final w in _edits(s))
        if (candidates.length < 4 && _canUse(w) && !candidates.contains(w))
          candidates.add(w);

    return candidates.toSet();
  }

  @override
  Future<CityResult> checkCity(String city) async {
    final props = _data[city];

    if (props == null) return CityResult.CITY_NOT_FOUND;
    if (props.used) return CityResult.ALREADY_USED;
    return CityResult.OK;
  }

  bool _canUse(String s) => s.length > 1 && !(_data[s]?.used ?? true);

  List<String> _edits(String word) {
    List<String> result = [];
    String f = word[0];
    String s;
    for (int i = 0; i < word.length; ++i) {
      s = word.substring(0, i) + word.substring(i + 1);
      if (s.isNotEmpty && s[0] == f) result.add(s);
    }
    for (int i = 0; i < word.length - 1; ++i) {
      s = word.substring(0, i) +
          word.substring(i + 1, i + 2) +
          word.substring(i, i + 1) +
          word.substring(i + 2);
      if (s.isNotEmpty && s[0] == f) result.add(s);
    }
    for (int i = 0; i < word.length; ++i)
      for (var c = 'а'.runes.first; c <= 'я'.runes.first; ++c) {
        s = word.substring(0, i) +
            String.fromCharCode(c) +
            word.substring(i + 1);
        if (s.isNotEmpty && s[0] == f) result.add(s);
      }
    for (int i = 0; i <= word.length; ++i)
      for (var c = 'а'.runes.first; c <= 'я'.runes.first; ++c) {
        s = word.substring(0, i) + String.fromCharCode(c) + word.substring(i);
        if (s.isNotEmpty && s[0] == f) result.add(s);
      }
    return result;
  }
}
