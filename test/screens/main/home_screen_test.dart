import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';

Future<GamePreferences> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);

  return SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
}

Widget _provide(GamePreferences prefs, Widget child) =>
    RepositoryProvider<GamePreferences>.value(value: prefs, child: child);

Widget _app(HomeActions actions, GamePreferences prefs) =>
    RepositoryProvider<GamePreferences>.value(
      value: prefs,
      child: withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: Scaffold(body: HomeScreen(actions: actions)),
        ),
      ),
    );

final _noop = HomeActions(
  playVsComputer: () {},
  playTwoPlayers: () {},
  playWifi: () {},
  playOnline: () {},
  openSettings: () {},
  openProfile: () {},
);

void main() {
  testWidgets('home shows modes', (tester) async {
    await tester.pumpWidget(_app(_noop, await _prefs()));

    expect(find.text('С компьютером'), findsOneWidget);
    expect(find.text('Играть'), findsOneWidget);
    expect(find.text('Вдвоём'), findsOneWidget);
    expect(find.text('По Wi-Fi'), findsOneWidget);
    expect(find.text('Онлайн'), findsOneWidget);
  });

  testWidgets('home tiles call actions', (tester) async {
    final calls = <String>[];
    final actions = HomeActions(
      playVsComputer: () => calls.add('pc'),
      playTwoPlayers: () => calls.add('two'),
      playWifi: () => calls.add('wifi'),
      playOnline: () => calls.add('online'),
      openSettings: () => calls.add('settings'),
      openProfile: () => calls.add('profile'),
    );
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(actions, await _prefs()));

    await tester.tap(find.text('Играть'));
    await tester.tap(find.text('Вдвоём'));
    await tester.tap(find.text('По Wi-Fi'));
    await tester.tap(find.text('Онлайн'));
    await tester.tap(find.byTooltip('Настройки'));
    await tester.tap(find.byTooltip('Профиль'));

    expect(calls, ['pc', 'two', 'wifi', 'online', 'settings', 'profile']);
  });

  testWidgets('home fits 320px at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final prefs = await _prefs();
    await tester.pumpWidget(
      _provide(
        prefs,
        withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(body: HomeScreen(actions: _noop)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('home avatar shows the signed-in account', (tester) async {
    final account = RemoteAccount(
      LpsUser(
        id: 1,
        name: 'мария',
        provider: 'native',
        lastSeenAt: DateTime(2026),
      ),
    );

    final prefs = await _prefs();
    await tester.pumpWidget(
      _provide(
        prefs,
        withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            home: Scaffold(
              body: HomeScreen(
                actions: _noop,
                loadAccount: () async => account,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final avatar = tester.widget<D2Avatar>(
      find.descendant(
        of: find.byTooltip('Профиль'),
        matching: find.byType(D2Avatar),
      ),
    );
    expect(avatar.initials, 'М');
  });

  testWidgets('home loads the account again when it changes', (tester) async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    var loads = 0;
    RemoteAccount? account;

    final prefs = await _prefs();
    await tester.pumpWidget(
      _provide(
        prefs,
        withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            home: Scaffold(
              body: HomeScreen(
                actions: _noop,
                accountChanges: changes.stream,
                loadAccount: () async {
                  loads++;
                  return account;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(find.text('М'), findsNothing);

    account = RemoteAccount(
      LpsUser(
        id: 1,
        name: 'Мария',
        provider: 'native',
        lastSeenAt: DateTime(2026),
      ),
    );
    changes.add(null);
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.text('М'), findsOneWidget);

    account = null;
    changes.add(null);
    await tester.pumpAndSettle();

    expect(loads, 3);
    expect(find.text('М'), findsNothing);
  });

  group('variant switch', () {
    testWidgets('shows Classic selected by default', (tester) async {
      await tester.pumpWidget(_app(_noop, await _prefs()));

      expect(find.text('Классика'), findsOneWidget);
      expect(find.text('Маршрут'), findsOneWidget);
      expect(find.text('Город на последнюю букву предыдущего'), findsOneWidget);
    });

    testWidgets('shows the stored variant', (tester) async {
      await tester.pumpWidget(
        _app(_noop, await _prefs({'gameVariant': 'route'})),
      );

      expect(find.text('Очки — километры между городами'), findsOneWidget);
    });

    testWidgets('tap on Route stores it', (tester) async {
      final prefs = await _prefs();
      await tester.pumpWidget(_app(_noop, prefs));

      await tester.tap(find.text('Маршрут'));
      await tester.pump();

      expect(prefs.gameVariant, GameVariant.route);
      expect(find.text('Очки — километры между городами'), findsOneWidget);

      await tester.tap(find.text('Классика'));
      await tester.pump();

      expect(prefs.gameVariant, GameVariant.classic);
    });

    testWidgets('navigation starts the game with the stored variant', (
      tester,
    ) async {
      final prefs = await _prefs({'gameVariant': 'route'});
      final started = <GameConfig>[];
      late HomeActions actions;

      await tester.pumpWidget(
        _provide(
          prefs,
          MaterialApp(
            home: Builder(
              builder: (context) {
                actions = HomeActions.navigation(
                  context,
                  gameRoute: (config) {
                    started.add(config);

                    return MaterialPageRoute<void>(
                      builder: (_) => const Text('game'),
                    );
                  },
                );

                return const SizedBox();
              },
            ),
          ),
        ),
      );

      actions.playVsComputer();
      await tester.pumpAndSettle();

      expect(started.single.gameMode, GameMode.playerVsAndroid);
      expect(started.single.variant, GameVariant.route);
    });
  });
}
