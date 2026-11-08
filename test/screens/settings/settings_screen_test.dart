import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  final themeNames = t.themes.themeNames;

  late GamePreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'theme': 'default'});
    prefs = SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
  });

  testWidgets('theme row shows the theme chosen after the screen was built', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [RepositoryProvider<GamePreferences>.value(value: prefs)],
        child: withTranslations(const MaterialApp(home: SettingsScreen())),
      ),
    );
    expect(find.text(themeNames['default']!), findsOneWidget);

    // What ThemeManagerScreen does while Settings stays on the stack.
    prefs.theme = 'autumn';

    // Any row tap rebuilds the list once its action completes.
    await tester.tap(find.text(t.settings.settingsItemTitles.sound));
    await tester.pumpAndSettle();

    expect(find.text(themeNames['autumn']!), findsOneWidget);
    expect(find.text(themeNames['default']!), findsNothing);
  });
}
