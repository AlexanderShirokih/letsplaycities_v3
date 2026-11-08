import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

import '../../../remote/fake_api_repository_factory.dart';

/// Lets the test decide when [connect] finishes and what the server says
/// while the user waits.
class _FakeGameClient implements RemoteGameClient {
  final connectResult = Completer<void>();
  final _waiting = StreamController<WaitingEvent>.broadcast();
  final _closes = StreamController<GameConnectionClose>.broadcast();
  bool connected = false;
  int playCalls = 0;
  int cancels = 0;

  /// What [configFor] returns
  GameConfig config = const GameConfig(gameMode: GameMode.network);

  @override
  Future<LpsUser> connect() async {
    await connectResult.future;
    connected = true;

    return LpsUser(
      id: _owner,
      name: 'owner',
      provider: 'native',
      lastSeenAt: DateTime(2026),
    );
  }

  @override
  Future<void> find() async {
    playCalls++;
    if (!connected) {
      throw const RemoteIOException('Socket channel is not opened');
    }
  }

  @override
  Stream<WaitingEvent> get waiting => _waiting.stream;

  @override
  Stream<GameConnectionClose> get closes => _closes.stream;

  @override
  GameConfig configFor(Match match) => config;

  @override
  void cancel() => cancels++;

  /// The server pairs the user with an opponent
  void match() => _waiting.add(
    const Match(
      gameId: 1,
      opponent: MatchOpponent(
        id: 2,
        name: 'opponent',
        friendship: Friendship.none,
      ),
      youStart: true,
      moveTimeSec: 30,
    ),
  );

  /// The socket breaks
  void drop() => _closes.add((code: null, reason: 'lost'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs [body] in its own error zone and returns the errors nobody handled.
/// The fake and the bloc have to be created inside [body]: a future does not
/// deliver its error into a different error zone.
Future<List<Object>> _uncaughtErrorsOf(Future<void> Function() body) async {
  final uncaught = <Object>[];
  await runZonedGuarded(body, (error, _) => uncaught.add(error));
  return uncaught;
}

class _FakeApiRepository extends Fake implements ApiRepository {}

const _owner = 1;

WaitingRoomBloc _createBloc(
  _FakeGameClient client, {
  ApiRepositoryFactory Function()? apiRepositories,
}) => WaitingRoomBloc(
  client,
  _owner,
  apiRepositories:
      apiRepositories ?? () => throw StateError('No game is started'),
);

void main() {
  test('a connected random request waits for opponents', () async {
    late WaitingRoomState state;
    late int playCalls;

    final uncaught = await _uncaughtErrorsOf(() async {
      final client = _FakeGameClient();
      final bloc = _createBloc(client);

      bloc.add(const NewGameRequestEvent());
      client.connectResult.complete();
      await pumpEventQueue();

      state = bloc.state;
      playCalls = client.playCalls;
      await bloc.close();
    });

    expect(uncaught, isEmpty);
    expect(state, const WaitingForOpponentsState(null));
    expect(playCalls, 1);
  });

  test('a started game carries a repository for the owner from the factory '
      'current when the game starts', () async {
    const config = GameConfig(gameMode: GameMode.network);
    final repository = _FakeApiRepository();
    final apiRepositories = FakeApiRepositoryFactory(repository);
    var lookups = 0;
    late int lookupsBeforeStart;
    final states = <WaitingRoomState>[];

    final uncaught = await _uncaughtErrorsOf(() async {
      final client = _FakeGameClient()..config = config;
      final bloc = _createBloc(
        client,
        apiRepositories: () {
          lookups++;
          return apiRepositories;
        },
      );
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const NewGameRequestEvent());
      client.connectResult.complete();
      await pumpEventQueue();
      lookupsBeforeStart = lookups;

      client.match();
      await pumpEventQueue();

      await subscription.cancel();
      await bloc.close();
    });

    expect(uncaught, isEmpty);
    expect(lookupsBeforeStart, 0);
    expect(lookups, 1);
    expect(apiRepositories.userIds, [_owner]);
    expect(
      states.whereType<StartGameState>().single,
      isA<StartGameState>()
          .having((s) => s.config, 'config', same(config))
          .having((s) => s.apiRepository, 'apiRepository', same(repository)),
    );
    expect(states.last, isA<WaitingRoomInitial>());
  });

  test('Cancel tapped while connecting is not followed by find()', () async {
    late WaitingRoomState stateAfterCancel;
    late int playCalls;

    final uncaught = await _uncaughtErrorsOf(() async {
      final client = _FakeGameClient();
      final bloc = _createBloc(client);

      bloc.add(const NewGameRequestEvent());
      await pumpEventQueue();
      // Cancel waits in the queue until connect() returns.
      bloc.add(const CancelEvent());
      client.connectResult.complete();
      await pumpEventQueue();

      stateAfterCancel = bloc.state;
      playCalls = client.playCalls;
      await bloc.close();
    });

    expect(uncaught, isEmpty);
    expect(stateAfterCancel, isA<WaitingRoomInitial>());
    expect(playCalls, 0);
  });

  test('a connection failure after close() does not add events', () async {
    final uncaught = await _uncaughtErrorsOf(() async {
      final client = _FakeGameClient();
      final bloc = _createBloc(client);

      bloc.add(const NewGameRequestEvent());
      await pumpEventQueue();

      // The screen goes away while connect() is still pending.
      final closing = bloc.close();
      await pumpEventQueue();
      client.connectResult.completeError(
        const ConnectionException('Connection refused'),
      );
      await closing;
      await pumpEventQueue();
    });

    expect(uncaught, isEmpty);
  });

  test('a lost socket while waiting shows the connection error', () async {
    late WaitingRoomState state;

    final uncaught = await _uncaughtErrorsOf(() async {
      final client = _FakeGameClient();
      final bloc = _createBloc(client);

      bloc.add(const NewGameRequestEvent());
      client.connectResult.complete();
      await pumpEventQueue();

      client.drop();
      await pumpEventQueue();

      state = bloc.state;
      await bloc.close();
    });

    expect(uncaught, isEmpty);
    expect(state, const WaitingRoomConnectionError());
  });

  test('closing while waiting cancels the search, socket stays', () async {
    late int cancels;

    final uncaught = await _uncaughtErrorsOf(() async {
      final client = _FakeGameClient();
      final bloc = _createBloc(client);

      bloc.add(const NewGameRequestEvent());
      client.connectResult.complete();
      await pumpEventQueue();

      await bloc.close();
      client.drop();
      await pumpEventQueue();

      cancels = client.cancels;
    });

    expect(uncaught, isEmpty);
    expect(cancels, 1);
  });
}
