import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/multiplayer/lan_scope.dart';
import 'package:lets_play_cities/screens/multiplayer/local_multiplayer_screen.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
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

class _FakeAccountManager extends Fake implements AccountManager {
  @override
  Future<RemoteAccount?> getLastSignedInAccount() async => null;
}

class _FakePreferences extends Fake implements GamePreferences {
  @override
  String get lastNativeLogin => 'Вася';

  @override
  bool get onlineChatEnabled => true;
}

Widget _app() => withTranslations(
  MaterialApp(
    theme: buildAppTheme(Brightness.light),
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
      ..registerSingleton<AccountManager>(_FakeAccountManager())
      ..registerSingleton<GamePreferences>(_FakePreferences());
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

  testWidgets('leaving the waiting room of a hosted game stops the host', (
    tester,
  ) async {
    // Completed inside the fake time of the test
    final host = _FakeServer()..setUpGate.complete();
    final mainConfig = AppConfig.forHost('main.test');
    GetIt.instance
      ..unregister<ServerGameController>()
      ..registerSingleton<ServerGameController>(host)
      ..registerSingleton<AppConfig>(mainConfig)
      ..registerSingleton<ApiRepositoryFactory>(
        ApiRepositoryFactory.main(
          mainConfig,
          MemoryTokenStore(),
          onError: (_, _) {},
        ),
      );
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Создать игру'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));

    expect(GetIt.instance.currentScopeName, lanGameScopeName);
    // The waiting room looks for the guest at once, without a button
    expect(find.byType(GameWaitingRoomScreen), findsOneWidget);
    expect(find.text('Найти соперника'), findsNothing);
    expect(host.isRunning, isTrue);

    await tester.tap(find.byTooltip('Назад').last);
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    // The waiting room has opened a real socket: it closes in real time,
    // and its timeout is in the fake one
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(seconds: 11));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(GetIt.instance.currentScopeName, isNot(lanGameScopeName));
    expect(host.closeCalls, 1);
    expect(host.isRunning, isFalse);
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
            theme: buildAppTheme(Brightness.light),
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
