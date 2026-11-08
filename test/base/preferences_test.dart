import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Stored codes of the enums. Installed apps already hold these numbers, so
// renaming or reordering an enum must not change them.
const difficultyCodes = {
  Difficulty.easy: 0,
  Difficulty.medium: 1,
  Difficulty.hard: 2,
};

const scoringTypeCodes = {
  ScoringType.byScore: 0,
  ScoringType.byTime: 1,
  ScoringType.lastMove: 2,
};

const updatePeriodCodes = {
  DictionaryUpdatePeriod.never: 0,
  DictionaryUpdatePeriod.threeHours: 1,
  DictionaryUpdatePeriod.daily: 2,
};

void main() {
  late SharedPreferences store;
  late GamePreferences prefs;

  /// Starts the app with [stored] already in the platform store. Keys are
  /// given without the plugin's 'flutter.' prefix.
  Future<void> launch([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues(stored);
    store = await SharedPreferences.getInstance();
    prefs = SharedPreferencesGamePrefs(store);
  }

  /// Re-reads the platform store, as the next app launch would.
  Future<GamePreferences> relaunch() async {
    await store.reload();
    return SharedPreferencesGamePrefs(store);
  }

  /// The raw value under [key] in the platform store.
  Future<Object?> stored(String key) async {
    await store.reload();
    return store.get(key);
  }

  group('on a fresh install', () {
    setUp(launch);

    test('uses the default settings', () {
      expect(prefs.wordsDifficulty, Difficulty.easy);
      expect(prefs.correctionEnabled, isTrue);
      expect(prefs.soundEnabled, isTrue);
      expect(prefs.onlineChatEnabled, isTrue);
      expect(prefs.timeLimit, 60);
      expect(prefs.scoringType, ScoringType.byScore);
      expect(prefs.scoringData, isEmpty);
      expect(prefs.lastDictionaryCheckDate.millisecondsSinceEpoch, 0);
      expect(prefs.dictionaryUpdatePeriod, DictionaryUpdatePeriod.threeHours);
      expect(prefs.themeMode, AppThemeMode.system);
      expect(prefs.lastNativeLogin, isEmpty);
      expect(prefs.hotseatNames, isEmpty);
      expect(prefs.recentCountries, isEmpty);
    });

    test('reports the first launch only once, across restarts', () async {
      expect(prefs.isFirstLaunch, isTrue);
      expect(prefs.isFirstLaunch, isFalse);

      expect(await stored('firstLaunch'), isFalse);
      expect((await relaunch()).isFirstLaunch, isFalse);
    });
  });

  group('changed settings survive a restart', () {
    setUp(launch);

    test('switches', () async {
      prefs.correctionEnabled = false;
      prefs.soundEnabled = false;
      prefs.onlineChatEnabled = false;

      final restarted = await relaunch();
      expect(restarted.correctionEnabled, isFalse);
      expect(restarted.soundEnabled, isFalse);
      expect(restarted.onlineChatEnabled, isFalse);

      restarted.soundEnabled = true;
      expect((await relaunch()).soundEnabled, isTrue);
    });

    test('time limit, including 0 for no timer', () async {
      prefs.timeLimit = 0;
      expect((await relaunch()).timeLimit, 0);

      prefs.timeLimit = 180;
      expect((await relaunch()).timeLimit, 180);
      expect(await stored('timeLimit'), 180);
    });

    test('themeMode defaults to system and round-trips', () async {
      expect(prefs.themeMode, AppThemeMode.system);

      prefs.themeMode = AppThemeMode.dark;
      expect((await relaunch()).themeMode, AppThemeMode.dark);
    });

    test('last native login', () async {
      prefs.lastNativeLogin = 'Игрок 1';
      expect((await relaunch()).lastNativeLogin, 'Игрок 1');
    });

    test('prefs hotseatNames round-trip', () async {
      prefs.hotseatNames = ['Аня', 'Боря'];

      expect((await relaunch()).hotseatNames, ['Аня', 'Боря']);
      expect(await stored('hotseatNames'), ['Аня', 'Боря']);
    });

    test('prefs recentCountries round-trip, at most five', () async {
      prefs.recentCountries = [91, 3, 7, 12, 40, 55];

      expect((await relaunch()).recentCountries, [91, 3, 7, 12, 40]);
      expect(await stored('recentCountries'), ['91', '3', '7', '12', '40']);
    });

    test('dictionary check date, to the millisecond', () async {
      final checkedAt = DateTime.utc(2026, 11, 7, 12, 30, 15, 250);
      prefs.lastDictionaryCheckDate = checkedAt;

      final restored = (await relaunch()).lastDictionaryCheckDate;
      expect(restored.isAtSameMomentAs(checkedAt), isTrue);
      expect(await stored('lastDictionaryCheckDate'), 1794054615250);
    });

    test('score data, including non-ASCII text', () async {
      const json = '{"город":"Москва"}';
      prefs.scoringData = json;
      expect((await relaunch()).scoringData, json);
    });

    test('achievements progress, as JSON', () async {
      expect(prefs.achievementsProgress, isEmpty);

      prefs.achievementsProgress = {'write15Cities': 12, 'changeTheme': 1};

      expect((await relaunch()).achievementsProgress, {
        'write15Cities': 12,
        'changeTheme': 1,
      });
      expect(
        await stored('achievementsProgress'),
        '{"write15Cities":12,"changeTheme":1}',
      );
    });
  });

  group('storage format', () {
    test('every enum value has a pinned code', () {
      expect(difficultyCodes.keys, unorderedEquals(Difficulty.values));
      expect(scoringTypeCodes.keys, unorderedEquals(ScoringType.values));
      expect(
        updatePeriodCodes.keys,
        unorderedEquals(DictionaryUpdatePeriod.values),
      );
    });

    for (final MapEntry(key: difficulty, value: code)
        in difficultyCodes.entries) {
      test('difficulty $difficulty is stored as $code', () async {
        await launch();
        prefs.wordsDifficulty = difficulty;
        expect(await stored('wordsDifficulty'), code);

        await launch({'wordsDifficulty': code});
        expect(prefs.wordsDifficulty, difficulty);
      });
    }

    for (final MapEntry(key: scoringType, value: code)
        in scoringTypeCodes.entries) {
      test('scoring type $scoringType is stored as $code', () async {
        await launch();
        prefs.scoringType = scoringType;
        expect(await stored('scoringType'), code);

        await launch({'scoringType': code});
        expect(prefs.scoringType, scoringType);
      });
    }

    for (final MapEntry(key: period, value: code)
        in updatePeriodCodes.entries) {
      test('update period $period is stored as $code', () async {
        await launch();
        prefs.dictionaryUpdatePeriod = period;
        expect(await stored('dictionaryUpdatePeriod'), code);

        await launch({'dictionaryUpdatePeriod': code});
        expect(prefs.dictionaryUpdatePeriod, period);
      });
    }

    test('score data is stored as base64 of its UTF-8 bytes', () async {
      await launch();
      prefs.scoringData = '{"a":1}';
      expect(await stored('scoringData'), 'eyJhIjoxfQ==');

      prefs.scoringData = '{"город":"Москва"}';
      expect(
        await stored('scoringData'),
        'eyLQs9C+0YDQvtC0Ijoi0JzQvtGB0LrQstCwIn0=',
      );
    });

    test('reads the values an installed app has stored', () async {
      // A signed-in player: integers for enums, the time limit in seconds,
      // and the score as NO_WRAP base64.
      await launch({
        'correctionEnabled': false,
        'onlineChatEnabled': false,
        'soundEnabled': false,
        'firstLaunch': false,
        'wordsDifficulty': 2,
        'timeLimit': 180,
        'scoringType': 2,
        'dictionaryUpdatePeriod': 2,
        'lastDictionaryCheckDate': 1600000000000,
        'scoringData':
            'eyJzY29yaW5nR3JvdXBzIjpbeyJtYWluIjp7InR5cGUiOiAiaW50IiwgIm5hbWUi'
            'OiAidHciLCAidmFsdWUiOiA0Mn19XX0=',
        'lastNativeLogin': 'Игрок',
      });

      expect(prefs.correctionEnabled, isFalse);
      expect(prefs.onlineChatEnabled, isFalse);
      expect(prefs.soundEnabled, isFalse);
      expect(prefs.isFirstLaunch, isFalse);
      expect(prefs.wordsDifficulty, Difficulty.hard);
      expect(prefs.timeLimit, 180);
      expect(prefs.scoringType, ScoringType.lastMove);
      expect(prefs.dictionaryUpdatePeriod, DictionaryUpdatePeriod.daily);
      expect(
        prefs.lastDictionaryCheckDate.millisecondsSinceEpoch,
        1600000000000,
      );
      expect(
        prefs.scoringData,
        '{"scoringGroups":[{"main":'
        '{"type": "int", "name": "tw", "value": 42}}]}',
      );
      expect(prefs.lastNativeLogin, 'Игрок');
    });

    test('empty stored score data reads as no score data', () async {
      await launch({'scoringData': ''});
      expect(prefs.scoringData, isEmpty);
    });

    test('broken achievements progress reads as no progress', () async {
      await launch({'achievementsProgress': 'not json'});
      expect(prefs.achievementsProgress, isEmpty);
    });
  });

  group('old credentials', () {
    test('old uid/uhash keys are removed on first start', () async {
      SharedPreferences.setMockInitialValues({
        'uid': 42,
        'uhash': 'secret-hash',
        'lastNativeLogin': 'Игрок',
      });
      store = await SharedPreferences.getInstance();

      prefs = await SharedPreferencesGamePrefs.open(store);

      await store.reload();
      expect(store.containsKey('uid'), isFalse);
      expect(store.containsKey('uhash'), isFalse);
      expect(prefs.lastNativeLogin, 'Игрок');
    });
  });
}
