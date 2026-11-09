import 'dart:math';

import 'package:lets_play_cities/base/dictionary/city_properties.dart';

import '../dictionary.dart';

/// Dictionary database implementation based on [Map].
/// Where map key is a city name, value is [CityProperties] describing this city.
class DictionaryServiceImpl extends DictionaryService {
  final Random _random;

  final Map<String, CityProperties> _data;

  /// [random] picks the word [getRandomWordByDifficulty] returns.
  DictionaryServiceImpl(this._data, {Random? random})
    : _random = random ?? Random();

  @override
  Map<String, CityProperties> getAll() => Map.unmodifiable(_data);

  @override
  List<String> getCandidates(String firstChar, Difficulty difficulty) => _data
      .entries
      .where((e) => e.key.startsWith(firstChar))
      .where(
        (e) =>
            !e.value.used &&
            e.value.countryCode != 0 &&
            e.value.difficulty <= difficulty.index,
      )
      .map((e) => e.key)
      .toList(growable: false);

  @override
  Future<String> getRandomWordByDifficulty(
    String firstChar,
    Difficulty difficulty,
  ) async {
    final candidates = getCandidates(firstChar, difficulty);

    if (candidates.isEmpty) return '';

    return candidates[_random.nextInt(candidates.length)];
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
    for (final prop in _data.values) {
      prop.reset();
    }
  }

  @override
  Stream<String> getCorrectionVariants(String city) async* {
    final list = _edits(city).toList();

    // Different edits can produce the same word, e.g. dropping either
    // letter of a doubled pair. Count each word once.
    final candidates = list
        .where((s) => _canUse(s))
        .toSet()
        .take(3)
        .toList(growable: true);

    if (candidates.isNotEmpty) {
      yield* Stream.fromIterable(candidates);
      return;
    }

    for (final s in list) {
      for (final w in _edits(s)) {
        if (candidates.length < 4 && _canUse(w) && !candidates.contains(w)) {
          candidates.add(w);
          yield w;
        }
      }
    }
  }

  @override
  Future<CityResult> checkCity(String city) async {
    final props = _data[city];

    if (props == null) return CityResult.cityNotFound;
    if (props.used) return CityResult.alreadyUsed;
    return CityResult.ok;
  }

  bool _canUse(String s) => s.length > 3 && !(_data[s]?.used ?? true);

  Iterable<String> _edits(String word) sync* {
    var f = word[0];
    String s;
    for (var i = 0; i < word.length; ++i) {
      s = word.substring(0, i) + word.substring(i + 1);
      if (s.isNotEmpty && s[0] == f) yield s;
    }
    for (var i = 0; i < word.length - 1; ++i) {
      s =
          word.substring(0, i) +
          word.substring(i + 1, i + 2) +
          word.substring(i, i + 1) +
          word.substring(i + 2);
      if (s.isNotEmpty && s[0] == f) yield s;
    }
    for (var i = 0; i < word.length; ++i) {
      for (var c = 'а'.runes.first; c <= 'я'.runes.first; ++c) {
        s =
            word.substring(0, i) +
            String.fromCharCode(c) +
            word.substring(i + 1);
        if (s.isNotEmpty && s[0] == f) yield s;
      }
    }
    for (var i = 0; i <= word.length; ++i) {
      for (var c = 'а'.runes.first; c <= 'я'.runes.first; ++c) {
        s = word.substring(0, i) + String.fromCharCode(c) + word.substring(i);
        if (s.isNotEmpty && s[0] == f) yield s;
      }
    }
  }
}
