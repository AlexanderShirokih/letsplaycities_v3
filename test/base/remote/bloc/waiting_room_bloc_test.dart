@Timeout(Duration(seconds: 5))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart'
    as protocol;

import '../../../remote/fake_game_connection.dart';

/// Opens only when the test completes [opened], or fails with its error
class _SlowConnection extends FakeGameConnection {
  final opened = Completer<void>();

  @override
  Future<LpsUser> ensureConnected() async {
    await opened.future;

    return super.ensureConnected();
  }
}

final _friend = LpsUser(
  id: 2,
  name: 'Пётр',
  provider: 'native',
  lastSeenAt: DateTime(2026),
);

const _match = protocol.Match(
  gameId: 5,
  opponent: protocol.MatchOpponent(
    id: 2,
    name: 'Пётр',
    friendship: Friendship.friends,
  ),
  youStart: true,
  moveTimeSec: 30,
);

final _now = DateTime(2026, 11, 9, 12);

void main() {
  late FakeGameConnection connection;
  late WaitingRoomBloc bloc;
  late List<WaitingRoomState> states;

  WaitingRoomBloc createBloc([FakeGameConnection? custom]) {
    connection = custom ?? connection;
    final created = WaitingRoomBloc(
      RemoteGameClient(connection, isLocal: false),
      clock: () => _now,
    );
    created.stream.listen(states.add);

    return created;
  }

  setUp(() {
    connection = FakeGameConnection();
    states = [];
    bloc = createBloc();
  });

  tearDown(() async {
    if (!bloc.isClosed) await bloc.close();
  });

  test('find → queued → match → starting', () async {
    bloc.add(const FindPressed());
    await pumpEventQueue();
    connection.receive(const protocol.Queued());
    await pumpEventQueue();
    connection.receive(_match);
    await pumpEventQueue();

    expect(states, [
      const Connecting(),
      Queued(_now),
      isA<Starting>().having(
        (s) => s.config.gameMode,
        'gameMode',
        GameMode.network,
      ),
      const Idle(),
    ]);
    expect(connection.sent, [const protocol.Find()]);
  });

  test('invite → sent stays inviting → declined finishes', () async {
    bloc.add(InvitePressed(_friend));
    await pumpEventQueue();
    connection.receive(
      const protocol.InviteStatus(2, protocol.InviteStatusKind.sent),
    );
    await pumpEventQueue();
    connection.receive(
      const protocol.InviteStatus(2, protocol.InviteStatusKind.declined),
    );
    await pumpEventQueue();
    await bloc.close();

    expect(states, [
      Inviting(_friend),
      Inviting(_friend, sent: true),
      InviteFinished(_friend, protocol.InviteStatusKind.declined),
    ]);
    // A finished invitation has nothing to cancel
    expect(connection.sent, [const protocol.Invite(2)]);
  });

  test('invite expired finishes with expired', () async {
    bloc.add(InvitePressed(_friend));
    await pumpEventQueue();
    connection.receive(
      const protocol.InviteStatus(2, protocol.InviteStatusKind.expired),
    );
    await pumpEventQueue();

    expect(
      bloc.state,
      InviteFinished(_friend, protocol.InviteStatusKind.expired),
    );
  });

  test('cancel while queued sends cancel and returns idle', () async {
    bloc.add(const FindPressed());
    await pumpEventQueue();
    connection.receive(const protocol.Queued());
    await pumpEventQueue();

    bloc.add(const CancelPressed());
    await pumpEventQueue();
    connection.receive(const protocol.Queued());
    await pumpEventQueue();

    expect(bloc.state, const Idle());
    expect(connection.sent, [const protocol.Find(), const protocol.Cancel()]);
  });

  test('rate_limited shows wait message', () async {
    bloc.add(InvitePressed(_friend));
    await pumpEventQueue();
    connection.receive(
      const protocol.ProtocolError(protocol.ProtocolError.rateLimited),
    );
    await pumpEventQueue();

    expect(bloc.state, RateLimited(_friend));
  });

  test('invalid_state while queued changes nothing', () async {
    bloc.add(const FindPressed());
    await pumpEventQueue();
    connection.receive(const protocol.Queued());
    await pumpEventQueue();
    connection.receive(
      const protocol.ProtocolError(protocol.ProtocolError.invalidState),
    );
    await pumpEventQueue();

    expect(bloc.state, Queued(_now));
  });

  test(
    'replaced fails with replaced, the close after it changes nothing',
    () async {
      bloc.add(const FindPressed());
      await pumpEventQueue();
      connection.receive(
        const protocol.ProtocolError(protocol.ProtocolError.replaced),
      );
      await pumpEventQueue();
      connection.drop(code: 1001);
      await pumpEventQueue();

      expect(states.whereType<Failed>(), hasLength(1));
      expect(
        bloc.state,
        isA<Failed>().having(
          (s) => s.error,
          'error',
          isA<ProtocolErrorException>().having(
            (e) => e.code,
            'code',
            'replaced',
          ),
        ),
      );
    },
  );

  test('a close for a replacement fails with replaced', () async {
    bloc.add(const FindPressed());
    await pumpEventQueue();
    connection.drop(code: 1001, reason: 'replaced');
    await pumpEventQueue();

    expect(
      bloc.state,
      isA<Failed>().having(
        (s) => s.error,
        'error',
        isA<ProtocolErrorException>().having((e) => e.code, 'code', 'replaced'),
      ),
    );
  });

  test('a lost socket fails with a connection error that retries', () async {
    bloc.add(const FindPressed());
    await pumpEventQueue();
    connection.receive(const protocol.Queued());
    await pumpEventQueue();
    connection.drop();
    await pumpEventQueue();

    final failed = bloc.state as Failed;
    expect(failed.error, isA<ConnectionException>());
    expect(failed.retry, const FindPressed());

    bloc.add(failed.retry!);
    await pumpEventQueue();
    expect(connection.sent, [const protocol.Find(), const protocol.Find()]);
  });

  test('a refused upgrade fails with the error of the server', () async {
    final refused = _SlowConnection();
    bloc = createBloc(refused);

    bloc.add(InvitePressed(_friend));
    await pumpEventQueue();
    refused.opened.completeError(
      const UnauthorizedException(401, 'unauthorized'),
    );
    await pumpEventQueue();

    expect(
      bloc.state,
      Failed(
        const UnauthorizedException(401, 'unauthorized'),
        retry: InvitePressed(_friend),
      ),
    );
  });

  test('cancel while connecting is not followed by find', () async {
    final slow = _SlowConnection();
    bloc = createBloc(slow);

    bloc.add(const FindPressed());
    await pumpEventQueue();
    bloc.add(const CancelPressed());
    await pumpEventQueue();
    slow.opened.complete();
    await pumpEventQueue();

    expect(bloc.state, const Idle());
    expect(slow.sent, isEmpty);
  });

  test(
    'closing while queued cancels, a match that crosses it is left',
    () async {
      bloc.add(const FindPressed());
      await pumpEventQueue();
      connection.receive(const protocol.Queued());
      await pumpEventQueue();

      await bloc.close();
      connection.receive(_match);
      await pumpEventQueue();

      expect(states.whereType<Starting>(), isEmpty);
      expect(connection.sent, [
        const protocol.Find(),
        const protocol.Cancel(),
        const protocol.Leave(),
      ]);
    },
  );

  test('invite while queued leaves the queue first', () async {
    bloc.add(const FindPressed());
    await pumpEventQueue();
    connection.receive(const protocol.Queued());
    await pumpEventQueue();

    bloc.add(InvitePressed(_friend));
    await pumpEventQueue();

    expect(bloc.state, Inviting(_friend));
    expect(connection.sent, [
      const protocol.Find(),
      const protocol.Cancel(),
      const protocol.Invite(2),
    ]);
  });

  test('an accepted invitation starts the game of its match', () async {
    bloc.add(const ReplyToInvite(3, true));
    await pumpEventQueue();
    connection.receive(_match);
    await pumpEventQueue();

    expect(states, [const Connecting(), isA<Starting>(), const Idle()]);
    expect(connection.sent, [const protocol.InviteReply(3, accept: true)]);
  });

  test('an answer to a withdrawn invitation finishes with expired', () async {
    bloc.add(const ReplyToInvite(3, true));
    await pumpEventQueue();
    connection.receive(
      const protocol.InviteStatus(3, protocol.InviteStatusKind.expired),
    );
    await pumpEventQueue();

    expect(
      bloc.state,
      const InviteFinished(null, protocol.InviteStatusKind.expired),
    );
  });

  test('a declined invitation is answered and stays idle', () async {
    bloc.add(const ReplyToInvite(3, false));
    await pumpEventQueue();

    expect(bloc.state, const Idle());
    expect(connection.sent, [const protocol.InviteReply(3, accept: false)]);
  });
}
