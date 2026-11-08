import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart'
    show WaitingRoomBloc, WaitingRoomState;
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';

import '../../i18n/translations_harness.dart';
import '../../remote/fake_api_repository_factory.dart';
import '../../remote/fake_game_connection.dart';
import 'online_fakes.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool get onlineChatEnabled => true;
}

class _PictureFactory extends FakeApiRepositoryFactory {
  _PictureFactory() : super(FakeApiRepository());

  @override
  AppConfig get pictureConfig => AppConfig.forHost('lps.test');
}

const _match = Match(
  gameId: 1,
  opponent: MatchOpponent(id: 2, name: 'Пётр', friendship: Friendship.none),
  youStart: false,
  moveTimeSec: 30,
);

final _t = AppLocale.ru.buildSync();

void main() {
  late FakeGameConnection connection;

  setUp(() {
    GetIt.instance
      ..registerSingleton<GameConnection>(connection = FakeGameConnection())
      ..registerSingleton<GamePreferences>(_FakePreferences())
      ..registerSingleton<ApiRepositoryFactory>(_PictureFactory());
  });

  tearDown(() => GetIt.instance.reset());

  Widget app(Widget child) =>
      withTranslations(MaterialApp(home: Scaffold(body: child)));

  WaitingRoomBloc blocOf(WidgetTester tester) => tester
      .element(find.byType(BlocConsumer<WaitingRoomBloc, WaitingRoomState>))
      .read<WaitingRoomBloc>();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  for (final (isLocal, mode) in [
    (true, GameMode.multiplayer),
    (false, GameMode.network),
  ]) {
    testWidgets('isLocal $isLocal plays a ${mode.name} game', (tester) async {
      final started = <GameConfig>[];
      await tester.pumpWidget(
        app(
          GameWaitingRoomScreen(
            isLocal: isLocal,
            onStarting: (_, config) => started.add(config),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.text(_t.online.connect));
      await settle(tester);
      connection.receive(_match);
      await settle(tester);

      expect(started.single.gameMode, mode);
    });
  }

  testWidgets('an accepted invitation is answered over the connection', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const GameWaitingRoomScreen(
          isLocal: false,
          request: FriendGameRequest(
            target: BaseProfileInfo(userId: 3, login: 'Пётр'),
            mode: FriendGameRequestType.join,
          ),
        ),
      ),
    );
    await settle(tester);

    expect(connection.sent, [const InviteReply(3, accept: true)]);
    expect(find.text(_t.online.connectingToServer), findsOneWidget);

    connection.receive(const InviteStatus(3, InviteStatusKind.expired));
    await settle(tester);

    expect(find.text(_t.online.invitationResult.replyExpired), findsOneWidget);
  });

  testWidgets('a rebuild keeps the same waiting room bloc', (tester) async {
    await tester.pumpWidget(app(const GameWaitingRoomScreen(isLocal: true)));
    final bloc = blocOf(tester);

    await tester.pumpWidget(app(const GameWaitingRoomScreen(isLocal: true)));

    expect(blocOf(tester), same(bloc));
  });

  testWidgets('leaving the screen while queued cancels the search', (
    tester,
  ) async {
    await tester.pumpWidget(app(const GameWaitingRoomScreen(isLocal: true)));
    final bloc = blocOf(tester);
    await tester.tap(find.text(_t.online.connect));
    await settle(tester);
    connection.receive(const Queued());
    await settle(tester);

    await tester.pumpWidget(app(const SizedBox()));
    await settle(tester);

    expect(connection.sent, [const Find(), const Cancel()]);
    expect(bloc.isClosed, isTrue);
  });

  testWidgets('a lost connection shows no connection, retry finds again', (
    tester,
  ) async {
    await tester.pumpWidget(app(const GameWaitingRoomScreen(isLocal: true)));
    await tester.tap(find.text(_t.online.connect));
    await settle(tester);

    connection.drop();
    await settle(tester);
    expect(find.text(_t.online.noConnection), findsOneWidget);

    await tester.tap(find.text(_t.online.reload));
    await settle(tester);

    expect(connection.sent, [const Find(), const Find()]);
  });

  testWidgets('another device shows the replaced text', (tester) async {
    await tester.pumpWidget(app(const GameWaitingRoomScreen(isLocal: false)));
    await tester.tap(find.text(_t.online.connect));
    await settle(tester);

    connection.drop(code: 1001, reason: 'replaced');
    await settle(tester);

    expect(find.text(_t.online.replaced), findsOneWidget);
  });
}
