import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/users.dart';

// close() should complete at once; the timeout only runs out when it hangs.
const _closeTimeout = Duration(milliseconds: 100);

/// A slow move with a 6-letter city: matches no combo by itself.
CityComboInfo _city({
  int timeMs = 10000,
  String word = 'москва',
  int country = 0,
}) => CityComboInfo.fromMoveParams(timeMs, word, country);

ComboSystem _comboSystemAfter(
  Iterable<CityComboInfo> cities, {
  bool canUseQuickTime = true,
}) {
  final comboSystem = ComboSystem(canUseQuickTime: canUseQuickTime);
  cities.forEach(comboSystem.addCity);
  return comboSystem;
}

/// Events the combo system sent while [cities] were added.
Future<List<Map<ComboType, int>>> _eventsFor(
  Iterable<CityComboInfo> cities,
) async {
  final comboSystem = _comboSystemAfter(cities);
  await comboSystem.close().timeout(_closeTimeout);
  return comboSystem.eventStream.toList();
}

void main() {
  test('close completes when nobody listened to the combo events', () async {
    final comboSystem = ComboSystem(canUseQuickTime: true);

    await expectLater(comboSystem.close().timeout(_closeTimeout), completes);
  });

  test('close of the users completes when nobody listened', () async {
    final users = UsersList([
      for (final name in ['first', 'second'])
        Player(
          LocalAccountInfo(
            name: name,
            picture: const PlaceholderPictureSource(),
          ),
        ),
    ]);

    await expectLater(users.close().timeout(_closeTimeout), completes);
  });

  test('combo events sent before the first listener still arrive', () async {
    final comboSystem = ComboSystem(canUseQuickTime: false);
    for (var i = 0; i < 3; i++) {
      comboSystem.addCity(CityComboInfo.fromMoveParams(10000, 'ухта', 0));
    }
    await comboSystem.close().timeout(_closeTimeout);

    final events = await comboSystem.eventStream.toList();

    expect(events, [
      {ComboType.shortWord: 2},
    ]);
  });

  group('CityComboInfo', () {
    test('a move of 5 seconds or less is quick', () {
      expect(_city(timeMs: 5000).isQuick, isTrue);
      expect(_city(timeMs: 5001).isQuick, isFalse);
    });

    test('a city of 4 letters or fewer is short', () {
      expect(_city(word: 'ухта').isShort, isTrue);
      expect(_city(word: 'анапа').isShort, isFalse);
    });

    test('a city of 8 letters or more is long', () {
      expect(_city(word: 'нью-йорк').isLong, isTrue);
      expect(_city(word: 'вологда').isLong, isFalse);
    });
  });

  group('combo levels', () {
    Map<ComboType, int> combosAfter(
      Iterable<CityComboInfo> cities, {
      bool canUseQuickTime = true,
    }) => _comboSystemAfter(
      cities,
      canUseQuickTime: canUseQuickTime,
    ).activeCombos;

    test('quick answer starts on the third quick move in a row', () {
      final quick = _city(timeMs: 1000);

      expect(combosAfter([quick, quick]), isEmpty);
      expect(combosAfter([quick, quick, quick]), {ComboType.quickTime: 1});
      expect(combosAfter([quick, quick, quick, quick]), {
        ComboType.quickTime: 2,
      });
    });

    test('quick answer never starts when it is not allowed', () {
      final quick = _city(timeMs: 1000);

      expect(
        combosAfter(List.filled(10, quick), canUseQuickTime: false),
        isEmpty,
      );
    });

    test('short and long cities start on the third in a row', () {
      final short = _city(word: 'ухта');
      final long = _city(word: 'архангельск');

      expect(combosAfter([short, short, short]), {ComboType.shortWord: 1});
      expect(combosAfter([long, long, long]), {ComboType.longWord: 1});
    });

    test('a city that does not fit ends the combo', () {
      final short = _city(word: 'ухта');

      expect(combosAfter([short, short, short, _city()]), isEmpty);
      expect(combosAfter([short, short, _city(), short]), isEmpty);
    });

    test('same country starts on the seventh city of one country', () {
      final russia = _city(country: 7);

      expect(combosAfter(List.filled(6, russia)), isEmpty);
      expect(combosAfter(List.filled(7, russia)), {ComboType.sameCountry: 1});
      expect(
        combosAfter([...List.filled(6, russia), _city(country: 8)]),
        isEmpty,
      );
    });

    test('cities without a known country never make a same country combo', () {
      expect(combosAfter(List.filled(10, _city(country: 0))), isEmpty);
    });

    test('different countries starts on the sixth distinct country', () {
      List<CityComboInfo> countries(List<int> codes) => [
        for (final code in codes) _city(country: code),
      ];

      expect(combosAfter(countries([1, 2, 3, 4, 5])), isEmpty);
      expect(combosAfter(countries([1, 2, 3, 4, 5, 6])), {
        ComboType.differentCountries: 1,
      });
      expect(combosAfter(countries([1, 2, 3, 4, 5, 6, 7])), {
        ComboType.differentCountries: 2,
      });
      // A repeated country cuts the streak back to the cities after it.
      expect(combosAfter(countries([1, 2, 3, 4, 5, 6, 2])), isEmpty);
    });

    test('active combos cannot be changed from outside', () {
      final combos = combosAfter(List.filled(3, _city(word: 'ухта')));

      expect(() => combos[ComboType.longWord] = 1, throwsUnsupportedError);
    });
  });

  group('multiplier', () {
    double multiplierAfter(Iterable<CityComboInfo> cities) =>
        _comboSystemAfter(cities).multiplier;

    test('is 1 without combos', () {
      expect(ComboSystem(canUseQuickTime: true).multiplier, 1.0);
      expect(multiplierAfter([_city(), _city()]), 1.0);
    });

    test('grows by 0.5 per combo level up to 3', () {
      final short = _city(word: 'ухта');

      expect(multiplierAfter(List.filled(3, short)), 1.5);
      expect(multiplierAfter(List.filled(4, short)), 2.0);
      expect(multiplierAfter(List.filled(5, short)), 2.5);
      expect(multiplierAfter(List.filled(6, short)), 3.0);
      expect(multiplierAfter(List.filled(10, short)), 3.0);
    });

    test('adds up the active combos', () {
      final quickAndShort = _city(timeMs: 1000, word: 'ухта');

      expect(multiplierAfter(List.filled(3, quickAndShort)), 3.0);
      expect(multiplierAfter(List.filled(6, quickAndShort)), 6.0);
    });
  });

  group('combo events', () {
    test('report each active combo with its rounded multiplier', () async {
      final short = _city(word: 'ухта');

      expect(await _eventsFor(List.filled(5, short)), [
        {ComboType.shortWord: 2},
        {ComboType.shortWord: 2},
        {ComboType.shortWord: 3},
      ]);
    });

    test('are not sent for cities that change no combo', () async {
      expect(await _eventsFor([_city(), _city(), _city()]), isEmpty);
    });

    test('are not sent when a city keeps every combo level', () async {
      // Seven distinct countries give level 2. Repeating the first country
      // drops it from the streak but keeps seven distinct ones in a row.
      final cities = [
        for (final code in [1, 2, 3, 4, 5, 6, 7, 1]) _city(country: code),
      ];

      expect(await _eventsFor(cities), [
        {ComboType.differentCountries: 2},
        {ComboType.differentCountries: 2},
      ]);
      expect(_comboSystemAfter(cities).activeCombos, {
        ComboType.differentCountries: 2,
      });
    });

    test('report the end of a combo with the combos left', () async {
      final short = _city(word: 'ухта');

      expect(await _eventsFor([short, short, short, _city()]), [
        {ComboType.shortWord: 2},
        <ComboType, int>{},
      ]);
    });
  });
}
