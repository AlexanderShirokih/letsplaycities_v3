import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/game_request_view.dart';
import 'package:lets_play_cities/screens/online/online_home_screen.dart';

import '../../i18n/translations_harness.dart';
import '../../remote/fake_api_repository_factory.dart';
import '../../remote/fake_game_connection.dart';
import 'online_fakes.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool get onlineChatEnabled => true;
}

class _PictureFactory extends FakeApiRepositoryFactory {
  _PictureFactory(super.repository);

  @override
  AppConfig get pictureConfig => AppConfig.forHost('lps.test');
}

final _t = AppLocale.ru.buildSync();
final _me = remoteAccount(1, 'Мария');

const _request = GameRequest(2, 'Alice');

void main() {
  late FakeApiRepository repository;
  late _PictureFactory apiRepositories;
  late FakeGameConnection connection;

  setUp(() {
    registerFakeAchievements();
    repository = FakeApiRepository()
      ..profiles[2] = userProfile(2, 'Alice', friendship: Friendship.friends);
    apiRepositories = _PictureFactory(repository);
    connection = FakeGameConnection();
    GetIt.instance
      ..registerSingleton<GamePreferences>(_FakePreferences())
      ..registerSingleton<ApiRepositoryFactory>(apiRepositories)
      ..registerSingleton<AccountManager>(FakeAccountManager(_me))
      ..registerSingleton<GameConnection>(connection);
  });

  /// The radar of a waiting search never settles
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget app(Widget home) => withTranslations(MaterialApp(home: home));

  /// Shows the invitation over whatever the app shows
  Future<void> showRequest(WidgetTester tester) async {
    // The sheet is as tall as its content
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final context = tester.element(find.byType(Scaffold).first);
    showD2Sheet<void>(
      context,
      builder: (_) => GameRequestView(request: _request),
    );
    await settle(tester);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      app(
        RepositoryProvider<RemoteAccount>.value(
          value: _me,
          child: OnlineHomeScreen(onStarting: (_, _) {}),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> pumpPlainApp(WidgetTester tester) async {
    await tester.pumpWidget(app(const Scaffold(body: Text('menu'))));
    await settle(tester);
  }

  testWidgets('shows who invites, with accept and decline', (tester) async {
    await pumpPlainApp(tester);
    await showRequest(tester);

    expect(find.text(_t.online.invitesYou(name: 'Alice')), findsOneWidget);
    expect(find.text(_t.accept), findsOneWidget);
    expect(find.text(_t.decline), findsOneWidget);
    expect(find.byType(D2Avatar), findsOneWidget);
    expect(repository.userCalls, [false]);
  });

  testWidgets('rebuilding the sheet keeps the profile it fetched', (
    tester,
  ) async {
    await pumpPlainApp(tester);
    await showRequest(tester);

    // The bottom sheet builds a new view while it is dragged.
    tester.view.physicalSize = const Size(1200, 2500);
    await settle(tester);

    expect(repository.userCalls, hasLength(1));
  });

  testWidgets('a name without a profile is still shown', (tester) async {
    repository.profiles.clear();
    await pumpPlainApp(tester);
    await showRequest(tester);

    expect(find.text(_t.online.invitesYou(name: 'Alice')), findsOneWidget);
    expect(find.text(_t.accept), findsOneWidget);
  });

  group('decline', () {
    testWidgets('sends inviteReply false over the shared connection and '
        'opens no home', (tester) async {
      await pumpPlainApp(tester);
      await showRequest(tester);

      await tester.tap(find.text(_t.decline));
      await settle(tester);

      expect(connection.sent, [const InviteReply(2, accept: false)]);
      expect(connection.connects, 1);
      expect(find.byType(GameRequestView), findsNothing);
      expect(find.byType(OnlineHomeScreen), findsNothing);
      // Nothing else uses the connection
      expect(connection.isConnected, isFalse);
    });

    testWidgets('goes through the open home and keeps its connection', (
      tester,
    ) async {
      await pumpHome(tester);
      await showRequest(tester);

      await tester.tap(find.text(_t.decline));
      await settle(tester);

      expect(connection.sent, [const InviteReply(2, accept: false)]);
      expect(connection.connects, 1);
      expect(connection.isConnected, isTrue);
      expect(find.byType(GameRequestView), findsNothing);
      expect(find.byType(OnlineHomeScreen), findsOneWidget);
    });

    testWidgets('stays tappable by its text with a large font', (tester) async {
      await tester.pumpWidget(
        app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: const Scaffold(body: Text('menu')),
          ),
        ),
      );
      await showRequest(tester);

      await tester.tap(find.text(AppLocale.ru.buildSync().decline));
      await settle(tester);

      expect(connection.sent, [const InviteReply(2, accept: false)]);
    });
  });

  group('accept', () {
    testWidgets('routes into the open home and replies true on its '
        'connection', (tester) async {
      await pumpHome(tester);
      await showRequest(tester);

      await tester.tap(find.text(_t.accept));
      await settle(tester);

      expect(find.byType(OnlineHomeScreen), findsOneWidget);
      expect(find.byType(GameRequestView), findsNothing);
      expect(connection.sent, [const InviteReply(2, accept: true)]);
      expect(find.text(_t.online.connectingToServer), findsOneWidget);
    });

    testWidgets('pops the screens above the open home', (tester) async {
      await pumpHome(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('friends')),
        ),
      );
      await settle(tester);
      await showRequest(tester);

      await tester.tap(find.text(_t.accept));
      await settle(tester);

      expect(find.text('friends'), findsNothing);
      expect(find.byType(OnlineHomeScreen), findsOneWidget);
      expect(connection.sent, [const InviteReply(2, accept: true)]);
    });

    testWidgets('opens the online home when none is open, once', (
      tester,
    ) async {
      await pumpPlainApp(tester);
      await showRequest(tester);

      await tester.tap(find.text(_t.accept));
      await settle(tester);

      expect(find.byType(OnlineHomeScreen), findsOneWidget);
      expect(find.byType(GameRequestView), findsNothing);
      expect(connection.sent, [const InviteReply(2, accept: true)]);
    });

    testWidgets('an answer to a withdrawn invitation says it is not valid '
        'any more', (tester) async {
      await pumpHome(tester);
      await showRequest(tester);
      await tester.tap(find.text(_t.accept));
      await settle(tester);

      connection.receive(const InviteStatus(2, InviteStatusKind.expired));
      await settle(tester);

      expect(
        find.text(_t.online.invitationResult.replyExpired),
        findsOneWidget,
      );
    });

    testWidgets('invalid_state ends the wait with an error', (tester) async {
      await pumpHome(tester);
      await showRequest(tester);
      await tester.tap(find.text(_t.accept));
      await settle(tester);

      connection.receive(const ProtocolError(ProtocolError.invalidState));
      await settle(tester);

      expect(find.text(_t.online.connectingToServer), findsNothing);
      expect(
        find.text(_t.online.invitationResult.replyRejected),
        findsOneWidget,
      );
      expect(find.text(_t.online.connect), findsOneWidget);
    });

    testWidgets('during a network game accept is hidden', (tester) async {
      await pumpHome(tester);
      // The match of a find starts the game that now runs
      await tester.tap(find.text(_t.online.connect));
      await settle(tester);
      connection.receive(
        const Match(
          gameId: 1,
          opponent: MatchOpponent(
            id: 3,
            name: 'Пётр',
            friendship: Friendship.none,
          ),
          youStart: true,
          moveTimeSec: 30,
        ),
      );
      await settle(tester);
      await showRequest(tester);

      expect(find.text(_t.accept), findsNothing);
      expect(find.text(_t.decline), findsOneWidget);
    });
  });
}
