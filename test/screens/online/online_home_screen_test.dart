import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';
import 'package:lets_play_cities/screens/online/online_home_screen.dart';

import '../../i18n/translations_harness.dart';
import '../../remote/fake_api_repository_factory.dart';
import '../../remote/fake_game_connection.dart';
import 'online_fakes.dart';

/// A socket that welcomes every hello at once and keeps what was sent
class _FakeConnector implements AbstractSocketConnector {
  final controller = StreamController<SocketMessage>.broadcast();
  final sent = <ClientGameMessage>[];

  @override
  void connect() => scheduleMicrotask(
    () => controller.add(SocketMessage(SocketMessageType.connected)),
  );

  @override
  Stream<SocketMessage> get messageStream => controller.stream;

  @override
  void sendData(String data) {
    final message = _decodeClient(data);
    sent.add(message);
    if (message is Hello) {
      scheduleMicrotask(
        () => controller.add(
          SocketMessage(
            SocketMessageType.data,
            '{"type":"welcome","user":{"id":1,"name":"Мария",'
            '"avatarHash":null,"provider":"native",'
            '"lastSeenAt":1762560000000}}',
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() async {}
}

ClientGameMessage _decodeClient(String data) => switch (data) {
  _ when data.contains('"hello"') => const Hello(protocol: 1, client: ''),
  _ when data.contains('"find"') => const Find(),
  _ when data.contains('"cancel"') => const Cancel(),
  _ when data.contains('"invite"') => Invite(
    int.parse(RegExp(r'"userId":(\d+)').firstMatch(data)!.group(1)!),
  ),
  _ => throw StateError('Unexpected message $data'),
};

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool get onlineChatEnabled => true;

  @override
  String get lastNativeLogin => 'Мария';
}

class _PictureFactory extends FakeApiRepositoryFactory {
  _PictureFactory(super.repository);

  @override
  AppConfig get pictureConfig => AppConfig.forHost('lps.test');
}

/// Signs in until the token is dropped; then nobody is signed in.
class _SessionAccountManager extends FakeAccountManager {
  _SessionAccountManager(super.account);

  @override
  Future<RemoteAccount?> trySilentNative() async => null;
}

final _t = AppLocale.ru.buildSync();
final _me = remoteAccount(1, 'Мария');

void main() {
  late FakeApiRepository repository;
  late FakeAccountManager accountManager;
  late DateTime now;

  setUp(() {
    registerFakeAchievements();
    repository = FakeApiRepository();
    accountManager = _SessionAccountManager(_me);
    now = DateTime(2026, 11, 9, 12);
    GetIt.instance
      ..registerSingleton<GamePreferences>(_FakePreferences())
      ..registerSingleton<ApiRepositoryFactory>(_PictureFactory(repository))
      ..registerSingleton<AccountManager>(accountManager);
  });

  FakeGameConnection useFakeConnection() {
    final connection = FakeGameConnection();
    GetIt.instance.registerSingleton<GameConnection>(connection);

    return connection;
  }

  Widget app(Widget home) => withTranslations(MaterialApp(home: home));

  Widget home({LpsUser? invite, List<GameConfig>? started}) =>
      RepositoryProvider<RemoteAccount>.value(
        value: _me,
        child: OnlineHomeScreen(
          invite: invite,
          clock: () => now,
          onStarting: (_, config) => started?.add(config),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  testWidgets('find shows the search with its timer and starts the game', (
    tester,
  ) async {
    final connection = useFakeConnection();
    final started = <GameConfig>[];
    await tester.pumpWidget(app(home(started: started)));
    await settle(tester);

    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    expect(find.text(_t.online.connectingToServer), findsOneWidget);

    connection.receive(const Queued());
    await settle(tester);
    expect(find.text(_t.online.awaitingForOpp), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    now = now.add(const Duration(seconds: 67));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:07'), findsOneWidget);

    connection.receive(
      const Match(
        gameId: 1,
        opponent: MatchOpponent(
          id: 2,
          name: 'Пётр',
          friendship: Friendship.none,
        ),
        youStart: true,
        moveTimeSec: 30,
      ),
    );
    await settle(tester);

    expect(started.single.gameMode, GameMode.network);
    expect(connection.sent, [const Find()]);
    expect(find.text(_t.online.connect), findsOneWidget);
  });

  testWidgets('cancel while queued sends cancel and shows find again', (
    tester,
  ) async {
    final connection = useFakeConnection();
    await tester.pumpWidget(app(home()));
    await settle(tester);

    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    connection.receive(const Queued());
    await settle(tester);
    await tester.tap(find.text(_t.cancel));
    await settle(tester);

    expect(connection.sent, [const Find(), const Cancel()]);
    expect(find.text(_t.online.connect), findsOneWidget);
  });

  testWidgets('online home shows up to 3 friends, fresh first', (tester) async {
    useFakeConnection();
    final realNow = DateTime.now();
    repository.friendEntries = [
      friendEntry(
        2,
        'Старый',
        FriendStatus.friends,
        lastSeenAt: realNow.subtract(const Duration(days: 9)),
      ),
      friendEntry(
        3,
        'Сейчас',
        FriendStatus.friends,
        lastSeenAt: realNow.subtract(const Duration(minutes: 1)),
      ),
      friendEntry(
        4,
        'Вчера',
        FriendStatus.friends,
        lastSeenAt: realNow.subtract(const Duration(days: 1)),
      ),
      friendEntry(5, 'Заявка', FriendStatus.incoming, lastSeenAt: realNow),
      friendEntry(
        6,
        'Неделя',
        FriendStatus.friends,
        lastSeenAt: realNow.subtract(const Duration(days: 7)),
      ),
    ];

    await tester.pumpWidget(app(home()));
    await settle(tester);

    expect(find.text(_t.online.friendsTab), findsOneWidget);
    expect(find.text(_t.online.allFriends), findsOneWidget);
    final names = ['Сейчас', 'Вчера', 'Неделя'];
    final tops = [
      for (final name in names) tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('Старый'), findsNothing);
    expect(find.text('Заявка'), findsNothing);
    expect(find.text(_t.online.inviteShort), findsNWidgets(3));
    expect(find.bySemanticsLabel(RegExp(_t.online.lastSeen.now)), findsOne);
  });

  testWidgets('without friends the block is hidden', (tester) async {
    useFakeConnection();
    await tester.pumpWidget(app(home()));
    await settle(tester);

    expect(find.text(_t.online.friendsTab), findsNothing);
    expect(find.text(_t.online.allFriends), findsNothing);
  });

  testWidgets('an invitation shows its status with cancel, then its result', (
    tester,
  ) async {
    final connection = useFakeConnection();
    repository.friendEntries = [friendEntry(2, 'Пётр', FriendStatus.friends)];
    await tester.pumpWidget(app(home()));
    await settle(tester);

    await tester.tap(find.text(_t.online.inviteShort));
    await settle(tester);
    expect(find.text(_t.online.awaitingForInvite(login: 'Пётр')), findsOne);
    expect(find.text(_t.online.cancelInvite), findsOneWidget);

    connection.receive(const InviteStatus(2, InviteStatusKind.sent));
    await settle(tester);
    expect(find.text(_t.online.inviteSent), findsOneWidget);

    connection.receive(const InviteStatus(2, InviteStatusKind.declined));
    await settle(tester);
    expect(find.text(_t.online.invitationResult.declined), findsOneWidget);
    expect(find.text(_t.online.connect), findsOneWidget);
    expect(connection.sent, [const Invite(2)]);
  });

  testWidgets('rate_limited shows the wait message', (tester) async {
    final connection = useFakeConnection();
    final friend = lpsUser(2, 'Пётр');
    await tester.pumpWidget(app(home(invite: friend)));
    await settle(tester);

    connection.receive(const ProtocolError(ProtocolError.rateLimited));
    await settle(tester);

    expect(find.text(_t.online.rateLimited), findsOneWidget);
    expect(find.byType(ConnectionErrorView), findsNothing);
  });

  testWidgets('a lost connection shows no connection, retry searches again', (
    tester,
  ) async {
    final connection = useFakeConnection();
    await tester.pumpWidget(app(home()));
    await settle(tester);

    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    connection.drop();
    await settle(tester);

    expect(find.text(_t.online.noConnection), findsOneWidget);
    expect(find.text(_t.online.noConnectionHint), findsOneWidget);
    expect(find.text(_t.online.toMenu), findsOneWidget);

    await tester.tap(find.text(_t.online.reload));
    await settle(tester);

    expect(connection.sent, [const Find(), const Find()]);
  });

  testWidgets('another device shows the replaced text', (tester) async {
    final connection = useFakeConnection();
    await tester.pumpWidget(app(home()));
    await settle(tester);

    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    connection.receive(const ProtocolError(ProtocolError.replaced));
    await settle(tester);

    expect(find.text(_t.online.replaced), findsOneWidget);
  });

  testWidgets('a refused upgrade asks to sign in again', (tester) async {
    GetIt.instance.registerSingleton<GameConnection>(_RefusedConnection());
    await tester.pumpWidget(app(home()));
    await settle(tester);

    accountManager.account = null;
    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('invite from friends reuses one connection', (tester) async {
    final connectors = <_FakeConnector>[];
    GetIt.instance.registerSingleton<GameConnection>(
      GameConnection(
        url: 'wss://lps.test/v1/game',
        headers: () async => const {},
        clientName: 'lps-flutter/test',
        playerName: () => 'Мария',
        connectorFactory: (_, _) {
          final connector = _FakeConnector();
          connectors.add(connector);

          return connector;
        },
      ),
    );
    repository.friendEntries = [
      friendEntry(2, 'Пётр', FriendStatus.friends, lastSeenAt: DateTime.now()),
    ];
    await tester.pumpWidget(app(home()));
    await settle(tester);

    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    await tester.tap(find.text(_t.cancel));
    await settle(tester);

    await tester.tap(find.text(_t.online.allFriends));
    await tester.pumpAndSettle();
    expect(find.byType(OnlineFriendsScreen), findsOneWidget);
    await tester.tap(find.text(_t.online.inviteShort));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OnlineFriendsScreen), findsNothing);
    expect(find.text(_t.online.awaitingForInvite(login: 'Пётр')), findsOne);
    expect(connectors, hasLength(1));
    expect(connectors.single.sent, [
      const Hello(protocol: 1, client: ''),
      const Find(),
      const Cancel(),
      const Invite(2),
    ]);
  });

  testWidgets('Пригласить without a callback opens the online home', (
    tester,
  ) async {
    final connection = useFakeConnection();
    repository.friendEntries = [
      friendEntry(2, 'Пётр', FriendStatus.friends, lastSeenAt: DateTime.now()),
    ];
    await tester.pumpWidget(
      hostScreen(const OnlineFriendsScreen(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_t.online.inviteShort));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OnlineHomeScreen), findsOneWidget);
    expect(find.text(_t.online.awaitingForInvite(login: 'Пётр')), findsOne);
    expect(connection.sent, [const Invite(2)]);
  });

  testWidgets('the search and the friends fit 320 px at text scale 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final connection = useFakeConnection();
    repository.friendEntries = [
      for (var id = 2; id < 5; id++)
        friendEntry(
          id,
          'Константин Константинопольский $id',
          FriendStatus.friends,
          lastSeenAt: DateTime.now(),
        ),
    ];
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: home(),
        ),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(_t.online.inviteShort).first);
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(_t.online.cancelInvite));
    await settle(tester);
    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    connection.receive(const Queued());
    await settle(tester);
    expect(tester.takeException(), isNull);

    connection.drop();
    await settle(tester);
    expect(find.text(_t.online.noConnection), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Every upgrade is refused with 401
class _RefusedConnection extends FakeGameConnection {
  @override
  Future<LpsUser> ensureConnected() async =>
      throw const UnauthorizedException(401, 'unauthorized');
}
