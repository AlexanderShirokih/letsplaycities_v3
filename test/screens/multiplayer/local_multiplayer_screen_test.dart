import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/multiplayer/local_multiplayer_screen.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import '../../i18n/translations_harness.dart';

class _FakeServer implements ServerGameController {
  final setUpGate = Completer<void>();
  var closeCalls = 0;
  var runGameCalls = 0;
  var _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> setUp() async {
    await setUpGate.future;
    _running = true;
  }

  @override
  Future<void> runGame() async => runGameCalls++;

  @override
  Future<void> close() async {
    closeCalls++;
    _running = false;
  }
}

class _FakeLogger implements ErrorLogger {
  @override
  void log(String message) {}

  @override
  void error(Object error, StackTrace stackTrace) {}
}

class _FakeAccountManager extends Fake implements AccountManager {}

Widget _app() => withTranslations(
  MaterialApp(
    theme: buildD2Theme(Brightness.light),
    home: const LocalMultiplayerScreen(),
  ),
);

void main() {
  late _FakeServer server;

  setUp(() {
    server = _FakeServer();
    final getIt = GetIt.instance;
    getIt
      ..registerSingleton<ServerGameController>(server)
      ..registerSingleton<ErrorLogger>(_FakeLogger())
      ..registerSingleton<AppConfig>(
        AppConfig.forHost('localhost'),
        instanceName: 'local',
      )
      ..registerFactoryParam<AccountManager, AppConfig, void>(
        (config, _) => _FakeAccountManager(),
        instanceName: 'local',
      );
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('shows both cards and the hint', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('По Wi-Fi рядом'), findsOneWidget);
    expect(find.text('Создать игру'), findsOneWidget);
    expect(find.text('Присоединиться'), findsOneWidget);
    expect(
      find.text('Оба телефона должны быть в одной сети Wi-Fi'),
      findsOneWidget,
    );
  });

  testWidgets('create shows waiting card and cancel returns to initial', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Создать игру'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Вас видно рядом'), findsOneWidget);
    expect(find.text('Ждём соперника'), findsOneWidget);
    expect(find.text('Создать игру'), findsNothing);

    await tester.tap(find.text('Отменить'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Создать игру'), findsOneWidget);
    expect(find.text('Ждём соперника'), findsNothing);
    expect(server.closeCalls, 1);

    // The late setUp must neither start the game nor leave the server open
    server.setUpGate.complete();
    await tester.pump();
    await tester.pump();

    expect(server.runGameCalls, 0);
    expect(server.isRunning, isFalse);
    expect(find.text('Создать игру'), findsOneWidget);
  });

  for (final creating in [false, true]) {
    testWidgets('fits 320 px at text scale 1.3 (creating: $creating)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const LocalMultiplayerScreen(),
          ),
        ),
      );

      if (creating) {
        await tester.tap(find.text('Создать игру'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Ждём соперника'), findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    });
  }
}
