import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';

import '../../i18n/translations_harness.dart';

/// Returns the queued results one per call and repeats the last one.
class _FakeAccountManager implements AccountManager {
  final List<Future<RemoteAccount?> Function()> results;
  int calls = 0;

  _FakeAccountManager(this.results);

  @override
  Future<RemoteAccount?> getLastSignedInAccount() {
    final result = results[calls.clamp(0, results.length - 1)];
    calls++;
    return result();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePreferences implements GamePreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The first connect() fails like an unreachable server, later ones work.
class _FlakyGameClient implements RemoteGameClient {
  int connectCalls = 0;
  int playCalls = 0;
  final invites = <FriendGameRequest>[];

  @override
  Future<void> connect() async {
    if (connectCalls++ == 0) {
      throw const ConnectionException('Connection refused');
    }
  }

  @override
  Future<void> logIn() async {}

  @override
  Future<GameConfig> play() {
    playCalls++;
    return Completer<GameConfig>().future;
  }

  @override
  Future<dynamic> invite(FriendGameRequest request) {
    invites.add(request);
    return Completer<dynamic>().future;
  }

  @override
  Future<void> disconnect() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _account = RemoteAccount(
  LpsUser(id: 1, name: 'user', provider: 'native', lastSeenAt: DateTime(2026)),
);

final _t = AppLocale.ru.buildSync();

void _registerServices(AccountManager accountManager) {
  final config = AppConfig.forHost('localhost');
  GetIt.instance
    ..registerSingleton<AccountManager>(accountManager)
    ..registerSingleton<CloudMessagingService>(StubCloudMessagingService())
    ..registerSingleton<GamePreferences>(_FakePreferences())
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<ApiRepositoryFactory>(
      ApiRepositoryFactory.main(
        config,
        MemoryTokenStore(),
        onError: (e, s) => fail('$e'),
      ),
    );
}

Widget _app(Widget child) =>
    withTranslations(MaterialApp(home: Scaffold(body: child)));

WaitingRoomBloc _blocOf(WidgetTester tester) => tester
    .element(find.byType(BlocConsumer<WaitingRoomBloc, WaitingRoomState>))
    .read<WaitingRoomBloc>();

void main() {
  tearDown(() => GetIt.instance.reset());

  testWidgets('a failed account fetch shows an error and reload retries it', (
    tester,
  ) async {
    final accountManager = _FakeAccountManager([
      () => Future.error(FetchingException('offline', Uri())),
      () async => _account,
    ]);
    _registerServices(accountManager);

    await tester.pumpWidget(_app(const GameWaitingRoomScreen()));
    await tester.pump();

    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(ConnectionErrorView), findsOneWidget);

    await tester.tap(find.text(_t.online.reload));
    await tester.pump();
    await tester.pump();

    expect(accountManager.calls, 2);
    expect(find.byType(ConnectionErrorView), findsNothing);
    expect(find.text(_t.online.connect), findsOneWidget);
  });

  testWidgets('a missing account shows an error instead of loading', (
    tester,
  ) async {
    _registerServices(_FakeAccountManager([() async => null]));

    await tester.pumpWidget(_app(const GameWaitingRoomScreen()));
    await tester.pump();

    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(ConnectionErrorView), findsOneWidget);
  });

  testWidgets('a rebuild keeps the same waiting room bloc', (tester) async {
    _registerServices(_FakeAccountManager([() async => _account]));

    await tester.pumpWidget(_app(GameWaitingRoomScreen()));
    await tester.pump();
    final bloc = _blocOf(tester);

    await tester.pumpWidget(_app(GameWaitingRoomScreen()));
    await tester.pump();

    expect(_blocOf(tester), same(bloc));
  });

  testWidgets('leaving the screen closes the waiting room bloc', (
    tester,
  ) async {
    _registerServices(_FakeAccountManager([() async => _account]));

    await tester.pumpWidget(_app(const GameWaitingRoomScreen()));
    await tester.pump();
    final bloc = _blocOf(tester);

    await tester.pumpWidget(_app(const SizedBox()));
    await tester.pump();

    expect(bloc.isClosed, isTrue);
  });

  testWidgets('Connect after a failed friend invite invites the friend again', (
    tester,
  ) async {
    final client = _FlakyGameClient();
    const request = FriendGameRequest(
      target: BaseProfileInfo(userId: 2, login: 'friend'),
      mode: FriendGameRequestType.invite,
    );

    await tester.pumpWidget(
      _app(
        BlocProvider<WaitingRoomBloc>(
          create: (_) => WaitingRoomBloc(
            client,
            1,
            apiRepositories: () => throw StateError('No game is started'),
          )..add(const NewGameRequestEvent(request)),
          child: const WaitingRoomView(request: request),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(_t.online.connectionError), findsOneWidget);

    await tester.tap(find.text(_t.online.connect));
    await tester.pump();

    expect(client.connectCalls, 2);
    expect(client.invites, [request]);
    expect(client.playCalls, 0);

    // Disposes the waiting animation and closes the bloc.
    await tester.pumpWidget(const SizedBox());
  });
}
