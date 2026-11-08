import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/screens/common/theme_mode.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';

class _RecordingAchievements extends Fake implements AchievementsService {
  final unlocked = <Achievement>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => unlocked.add(achievement);
}

void main() {
  final t = AppLocale.ru.buildSync();
  final getIt = GetIt.instance;

  late GamePreferences prefs;
  late _RecordingAchievements achievements;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
    achievements = _RecordingAchievements();
    await getIt.reset();
    getIt.registerSingleton<GamePreferences>(prefs);
    getIt.registerSingleton<AchievementsService>(achievements);
    getIt.registerSingleton<ValueNotifier<AppThemeMode>>(
      ValueNotifier(prefs.themeMode),
      instanceName: themeModeNotifierName,
    );
  });

  tearDown(() => getIt.reset());

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<GamePreferences>.value(
        value: prefs,
        child: withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a difficulty segment writes the preference', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(t.settings.difficulty.hard));
    await tester.pump();

    expect(prefs.wordsDifficulty, Difficulty.hard);
    expect(
      tester
          .widget<D2Segmented<Difficulty>>(find.byType(D2Segmented<Difficulty>))
          .selected,
      Difficulty.hard,
    );
  });

  testWidgets('tapping a theme segment writes the preference and notifier', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(t.settings.themeMode.dark));
    await tester.pump();

    expect(prefs.themeMode, AppThemeMode.dark);
    expect(
      getIt
          .get<ValueNotifier<AppThemeMode>>(instanceName: themeModeNotifierName)
          .value,
      AppThemeMode.dark,
    );
    expect(achievements.unlocked, [Achievement.changeTheme]);
  });

  testWidgets('tapping the selected theme segment unlocks nothing', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(t.settings.themeMode.system));
    await tester.pump();

    expect(prefs.themeMode, AppThemeMode.system);
    expect(achievements.unlocked, isEmpty);
  });

  testWidgets('tapping the sound switch turns the sound off', (tester) async {
    await pumpScreen(tester);
    expect(prefs.soundEnabled, isTrue);

    await tester.tap(find.byType(D2Switch).at(2));
    await tester.pump();

    expect(prefs.soundEnabled, isFalse);
    expect(tester.widget<D2Switch>(find.byType(D2Switch).at(2)).value, isFalse);
  });

  testWidgets('a stored timer outside the list selects no segment', (
    tester,
  ) async {
    prefs.timeLimit = 300;

    await pumpScreen(tester);

    expect(
      tester.widget<D2Segmented<int>>(find.byType(D2Segmented<int>)).selected,
      isNull,
    );
    expect(prefs.timeLimit, 300);
  });

  testWidgets('the dictionary switch toggles never and daily', (tester) async {
    prefs.dictionaryUpdatePeriod = DictionaryUpdatePeriod.threeHours;
    await pumpScreen(tester);
    final dict = find.byType(D2Switch).at(3);
    expect(tester.widget<D2Switch>(dict).value, isTrue);

    await tester.tap(dict);
    await tester.pump();
    expect(prefs.dictionaryUpdatePeriod, DictionaryUpdatePeriod.never);
    expect(tester.widget<D2Switch>(dict).value, isFalse);

    await tester.tap(dict);
    await tester.pump();
    expect(prefs.dictionaryUpdatePeriod, DictionaryUpdatePeriod.daily);
    expect(tester.widget<D2Switch>(dict).value, isTrue);
  });

  testWidgets('the licenses row opens the license page', (tester) async {
    await pumpScreen(tester);

    final row = find.text(t.settings.licenses);
    await tester.scrollUntilVisible(row, 200);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
