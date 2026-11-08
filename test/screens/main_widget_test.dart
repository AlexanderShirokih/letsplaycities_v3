import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/screens/main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/translations_harness.dart';

void main() {
  tearDown(GetIt.instance.reset);

  testWidgets('MaterialApp follows the stored theme mode', (tester) async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final prefs = SharedPreferencesGamePrefs(
      await SharedPreferences.getInstance(),
    );
    final getIt = GetIt.instance;
    getIt.registerSingleton<GamePreferences>(prefs);
    getIt.registerSingleton<ValueNotifier<AppThemeMode>>(
      ValueNotifier(prefs.themeMode),
      instanceName: 'themeModeNotifier',
    );
    getIt.registerSingleton<CloudMessagingService>(StubCloudMessagingService());

    await tester.pumpWidget(withTranslations(const LetsPlayCitiesApp()));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
