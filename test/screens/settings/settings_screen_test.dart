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

  late GamePreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
  });

  testWidgets('shows the sound row and no theme row', (tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [RepositoryProvider<GamePreferences>.value(value: prefs)],
        child: withTranslations(const MaterialApp(home: SettingsScreen())),
      ),
    );

    expect(find.text(t.settings.settingsItemTitles.sound), findsOneWidget);
  });
}
