import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as theme;
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/game_results/game_results_screen.dart';

import '../../i18n/translations_harness.dart';

class _CountingAdManager extends Fake implements AdManager {
  int interstitialsShown = 0;

  @override
  Future<void> showInterstitial() async => interstitialsShown++;
}

class _TestUser extends User {
  _TestUser()
    : super(
        accountInfo: const LocalAccountInfo(
          name: 'Игрок',
          picture: PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) => throw UnimplementedError();
}

void main() {
  const appTheme = theme.Theme(
    name: 'test',
    primaryColor: Colors.blue,
    accentColor: Colors.amber,
    fillColor: Colors.white,
    borderColor: Colors.grey,
    messageMe: Colors.green,
    messageOther: Colors.orange,
  );

  late _CountingAdManager adManager;

  setUp(() {
    adManager = _CountingAdManager();
    GetIt.instance.registerSingleton<AdManager>(adManager);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('shows the interstitial once however often it rebuilds', (
    tester,
  ) async {
    final user = _TestUser();
    final result = GameResult(
      owner: user,
      matchResult: MatchResult.win,
      finishType: MoveFinishType.surrender,
      hasScore: false,
      finishRequester: user,
    );
    const config = GameConfig(gameMode: GameMode.playerVsAndroid);

    Widget app() => MultiRepositoryProvider(
      providers: [RepositoryProvider<theme.Theme>.value(value: appTheme)],
      // A new screen instance each time, as a parent rebuild would create.
      child: withTranslations(
        MaterialApp(home: GameResultsScreen(result, config)),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpWidget(app());
    await tester.pumpWidget(app());

    expect(
      find.text(AppLocale.ru.buildSync().gameResults.matchResult.win),
      findsOneWidget,
    );
    expect(adManager.interstitialsShown, 1);
  });
}
