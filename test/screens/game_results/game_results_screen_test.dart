import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/game/hotseat_setup_screen.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game_results/game_results_screen.dart';
import 'package:lets_play_cities/screens/game_results/game_share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';

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
  tearDown(() => GetIt.instance.reset());

  testWidgets('confetti only for a win', (tester) async {
    final user = _TestUser();
    const config = GameConfig(gameMode: GameMode.playerVsAndroid);

    Future<void> pump(MatchResult match) => tester.pumpWidget(
      withTranslations(
        MaterialApp(
          home: GameResultsScreen(
            GameResult(
              owner: user,
              matchResult: match,
              finishType: MoveFinishType.surrender,
              hasScore: false,
              finishRequester: user,
              summary: GameSummary.empty,
            ),
            config,
            key: ValueKey(match),
          ),
        ),
      ),
    );

    bool confetti() => find
        .byWidgetPredicate((w) => w.runtimeType.toString() == '_Confetti')
        .evaluate()
        .isNotEmpty;

    await pump(MatchResult.win);
    expect(confetti(), isTrue);

    await pump(MatchResult.draw);
    expect(
      find.text(AppLocale.ru.buildSync().gameResults.drawTitle),
      findsOneWidget,
    );
    expect(confetti(), isFalse);
  });

  testWidgets('replay of a game of two players opens the names first', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SharedPreferencesGamePrefs(
      await SharedPreferences.getInstance(),
    )..hotseatNames = ['Аня', 'Боря'];
    final user = _TestUser();
    final result = GameResult(
      owner: user,
      matchResult: MatchResult.win,
      finishType: MoveFinishType.surrender,
      hasScore: false,
      finishRequester: user,
      summary: GameSummary.empty,
    );
    const config = GameConfig(gameMode: GameMode.playerVsPlayer);

    await tester.pumpWidget(
      RepositoryProvider<GamePreferences>.value(
        value: prefs,
        child: withTranslations(
          MaterialApp(home: GameResultsScreen(result, config)),
        ),
      ),
    );

    await tester.tap(find.text('Сыграть ещё'));
    await tester.pumpAndSettle();

    expect(find.byType(HotseatSetupScreen), findsOneWidget);
    expect(find.byType(GameResultsScreen), findsNothing);
    expect(find.text('Аня'), findsOneWidget);
    expect(find.text('Боря'), findsOneWidget);
  });

  group('summary', () {
    GameResult resultWith({bool hasScore = true, GameSummary? summary}) =>
        GameResult(
          owner: _TestUser(),
          matchResult: MatchResult.win,
          finishType: MoveFinishType.surrender,
          hasScore: hasScore,
          finishRequester: _TestUser(),
          summary: summary ?? GameSummary.empty,
        );

    Future<void> pump(WidgetTester tester, GameResult result) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        withTranslations(
          MaterialApp(
            home: GameResultsScreen(
              result,
              const GameConfig(gameMode: GameMode.playerVsAndroid),
            ),
          ),
        ),
      );
    }

    testWidgets('shows win title, metrics and combos', (tester) async {
      await pump(
        tester,
        resultWith(
          summary: const GameSummary(
            citiesCount: 37,
            duration: Duration(minutes: 18, seconds: 42),
            longestCity: (city: 'петропавловск-камчатский', countryCode: 1),
            bestCombos: {ComboType.quickTime: 4},
            playerCountries: {1},
          ),
        ),
      );

      expect(find.text('Победа!'), findsOneWidget);
      expect(find.text('37'), findsOneWidget);
      expect(find.text('18:42'), findsOneWidget);
      expect(
        find.textContaining('Петропавловск-Камчатск', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Быстрый ответ'), findsOneWidget);
      expect(find.text('×${ComboSystem.badgeValue(4)}'), findsOneWidget);
    });

    testWidgets('hides score when result has no score', (tester) async {
      await pump(tester, resultWith(hasScore: false));

      expect(find.text('Игрок'), findsNothing);
      expect(find.text('Поделиться'), findsNothing);
    });

    testWidgets('hides metrics and combos of an empty summary', (tester) async {
      await pump(tester, resultWith());

      expect(find.text('городов'), findsNothing);
      expect(find.text('Комбо'), findsNothing);
    });

    testWidgets('shows only the three best combos', (tester) async {
      await pump(
        tester,
        resultWith(
          summary: const GameSummary(
            citiesCount: 5,
            duration: Duration(seconds: 90),
            longestCity: null,
            bestCombos: {
              ComboType.quickTime: 1,
              ComboType.shortWord: 6,
              ComboType.longWord: 4,
              ComboType.sameCountry: 2,
            },
            playerCountries: {},
          ),
        ),
      );

      expect(find.text('Быстрый ответ'), findsNothing);
      expect(find.text('Короткие города'), findsOneWidget);
      expect(find.text('Длинные города'), findsOneWidget);
      expect(find.text('Одна страна'), findsOneWidget);
    });

    const full = GameSummary(
      citiesCount: 137,
      duration: Duration(minutes: 58, seconds: 42),
      longestCity: (city: 'петропавловск-камчатский', countryCode: 1),
      bestCombos: {
        ComboType.quickTime: 4,
        ComboType.differentCountries: 6,
        ComboType.longWord: 5,
      },
      playerCountries: {1},
    );

    testWidgets('the share picture fits every part', (tester) async {
      final owner = _TestUser()..addPoints(1234);
      final opponent = _TestUser()..addPoints(987);

      await tester.pumpWidget(
        withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            home: Center(
              child: GameShareCard(
                GameResult(
                  owner: owner,
                  opponent: opponent,
                  matchResult: MatchResult.win,
                  finishType: MoveFinishType.surrender,
                  hasScore: true,
                  finishRequester: opponent,
                  summary: full,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Победа!'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('987'), findsOneWidget);
      expect(find.text('137'), findsOneWidget);
      expect(find.text('Разные страны'), findsOneWidget);
    });

    testWidgets('the share button shares the result once at a time', (
      tester,
    ) async {
      final owner = _TestUser()..addPoints(10);
      final sharing = Completer<void>();
      var shares = 0;

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        withTranslations(
          MaterialApp(
            home: GameResultsScreen(
              GameResult(
                owner: owner,
                matchResult: MatchResult.win,
                finishType: MoveFinishType.surrender,
                hasScore: true,
                finishRequester: owner,
                summary: full,
              ),
              const GameConfig(gameMode: GameMode.playerVsAndroid),
              onShare: (_) {
                shares++;
                return sharing.future;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Поделиться'));
      await tester.tap(find.text('Поделиться'));
      sharing.complete();
      await tester.pump();

      expect(shares, 1);
    });
  });
}
