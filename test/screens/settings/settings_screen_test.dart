import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_injection.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  final getIt = GetIt.instance;

  late GamePreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
    await getIt.reset();
    getIt.registerSingleton<GamePreferences>(prefs);
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
  });

  testWidgets('tapping the sound switch turns the sound off', (tester) async {
    await pumpScreen(tester);
    expect(prefs.soundEnabled, isTrue);

    await tester.tap(find.byType(D2Switch).at(2));
    await tester.pump();

    expect(prefs.soundEnabled, isFalse);
  });
}
