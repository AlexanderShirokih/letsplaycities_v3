@Timeout(Duration(seconds: 5))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/remote/remote_player.dart';

import '../fake_game_connection.dart';

class _FakeSession extends Fake implements GameSession {}

const _me = 1;
const _opponentId = 2;

Match _match({bool youStart = true, int moveTimeSec = 30}) => Match(
  gameId: 5,
  opponent: const MatchOpponent(
    id: _opponentId,
    name: 'Пётр',
    avatarHash: 'abc',
    friendship: Friendship.none,
  ),
  youStart: youStart,
  moveTimeSec: moveTimeSec,
);

void main() {
  late FakeGameConnection connection;
  late RemoteGameClient client;

  setUp(() {
    connection = FakeGameConnection();
    client = RemoteGameClient(connection, isLocal: false);
  });

  /// Starts a game against [_opponentId] and listens to its events
  Future<(GameConfig, List<GameEvent>)> startGame({
    RemoteGameClient? gameClient,
  }) async {
    final used = gameClient ?? client;
    await used.find();
    final config = used.configFor(_match());
    final events = <GameEvent>[];
    config.externalEventSource!(_FakeSession()).listen(events.add);

    return (config, events);
  }

  User owner(GameConfig config) =>
      config.usersListOverride!.all.firstWhere((user) => user is Player);

  RemotePlayer opponent(GameConfig config) =>
      config.usersListOverride!.all.whereType<RemotePlayer>().single;

  group('before the game', () {
    test('find connects and sends find', () async {
      await client.find();

      expect(connection.connects, 1);
      expect(connection.sent, [const Find()]);
    });

    test('invite, reply and cancel go over the connection', () async {
      await client.invite(3);
      await client.reply(4, false);
      client.cancel();

      expect(connection.sent, [
        const Invite(3),
        const InviteReply(4, accept: false),
        const Cancel(),
      ]);
    });

    test(
      'waiting passes the queue, invitations, the match and errors',
      () async {
        final events = <WaitingEvent>[];
        client.waiting.listen(events.add);

        connection
          ..receive(const Queued())
          ..receive(const ChatIn(2, 'привет'))
          ..receive(const InviteStatus(3, InviteStatusKind.sent))
          ..receive(_match())
          ..receive(const ProtocolError('rate_limited'));
        await pumpEventQueue();

        expect(events, [
          const Queued(),
          const InviteStatus(3, InviteStatusKind.sent),
          _match(),
          const ProtocolError('rate_limited'),
        ]);
      },
    );
  });

  group('configFor', () {
    const modes = {false: GameMode.network, true: GameMode.multiplayer};

    modes.forEach((isLocal, mode) {
      test('builds a ${mode.name} game on server authority', () async {
        final gameClient = RemoteGameClient(connection, isLocal: isLocal);
        await gameClient.find();

        final config = gameClient.configFor(_match(moveTimeSec: 45));

        expect(config.gameMode, mode);
        expect(config.serverAuthoritative, isTrue);
        expect(config.timeLimitOverride, 45);
      });
    });

    test('the player who starts moves first', () async {
      await client.find();

      final first = client.configFor(_match(youStart: true));
      final second = client.configFor(_match(youStart: false));

      expect(first.usersListOverride!.all.first, isA<Player>());
      expect(second.usersListOverride!.all.first, isA<RemotePlayer>());
    });

    test('users come from the welcome and the match, chat allowed', () async {
      final gameClient = RemoteGameClient(
        connection,
        isLocal: false,
        pictureConfig: AppConfig.forHost('lps.test'),
      );
      await gameClient.find();

      final config = gameClient.configFor(_match());
      final me = owner(config).accountInfo as RemoteAccount;
      final other = opponent(config).accountInfo as AdvancedAccountInfo;

      expect(me.userId, _me);
      expect(other.profileInfo.userId, _opponentId);
      expect(other.name, 'Пётр');
      expect(other.profileInfo.pictureUrl, contains('/avatars/2?v=abc'));
      expect(
        config.usersListOverride!.all.every((user) => user.isMessagesAllowed),
        isTrue,
      );
    });

    test('chat is off when the settings turn it off', () async {
      final gameClient = RemoteGameClient(
        connection,
        isLocal: false,
        chatEnabled: false,
      );
      final (config, events) = await startGame(gameClient: gameClient);

      connection.receive(const ChatIn(_opponentId, 'привет'));
      await pumpEventQueue();

      expect(owner(config).isMessagesAllowed, isFalse);
      expect(events, isEmpty);
    });
  });

  group('in the game', () {
    test('gameOver reasons map to finish types', () async {
      const types = {
        GameOverReason.timeout: MoveFinishType.timeout,
        GameOverReason.surrender: MoveFinishType.surrender,
        GameOverReason.opponentLeft: MoveFinishType.disconnected,
      };

      for (final MapEntry(key: reason, value: type) in types.entries) {
        for (final loser in [_me, _opponentId]) {
          final gameClient = RemoteGameClient(connection, isLocal: false);
          final (config, events) = await startGame(gameClient: gameClient);

          connection.receive(
            GameOver(reason: reason, loser: loser, words: 4, durationSec: 60),
          );
          await pumpEventQueue();

          final expectedLoser = loser == _me ? owner(config) : opponent(config);
          expect(
            events.single,
            isA<OnMoveFinished>()
                .having((e) => e.endType, 'endType', type)
                .having(
                  (e) => e.finishRequester,
                  'finishRequester',
                  same(expectedLoser),
                ),
            reason: '$reason, loser $loser',
          );
        }
      }
    });

    test(
      'opponent words come from accepted word messages by opponent',
      () async {
        final (config, _) = await startGame();

        connection
          ..receive(const WordResultMsg(_me, 'москва', WordStatus.accepted))
          ..receive(
            const WordResultMsg(_opponentId, 'анкара', WordStatus.unknown),
          )
          ..receive(
            const WordResultMsg(_opponentId, 'анапа', WordStatus.accepted),
          );
        await pumpEventQueue();

        // The word came before the move of the opponent began
        expect(await opponent(config).onCreateWord('а'), 'анапа');

        final next = opponent(config).onCreateWord('а');
        connection.receive(
          const WordResultMsg(_opponentId, 'амстердам', WordStatus.accepted),
        );

        expect(await next, 'амстердам');
      },
    );

    test('chat from the opponent becomes a message event', () async {
      final (config, events) = await startGame();

      connection.receive(const ChatIn(_opponentId, 'привет'));
      await pumpEventQueue();

      expect(
        events.single,
        isA<MessageEvent>()
            .having((e) => e.message, 'message', 'привет')
            .having((e) => e.owner, 'owner', same(opponent(config))),
      );
    });

    test('chat is clamped to 200 chars', () async {
      await startGame();

      client.sendChat('а' * 250);
      client.sendChat('😀' * 150 + 'б' * 100);

      final [first, second] = connection.sent
          .whereType<ChatMsg>()
          .map((m) => m.text)
          .toList();
      expect(first, 'а' * 200);
      expect(second, '😀' * 150 + 'б' * 50);
    });

    test('sendWord returns the verdict on the own word', () async {
      await startGame();

      final verdict = client.sendWord('Москва');
      connection
        ..receive(
          const WordResultMsg(_opponentId, 'анапа', WordStatus.accepted),
        )
        ..receive(const WordResultMsg(_me, 'москва', WordStatus.accepted));

      expect(
        await verdict,
        const WordResultMsg(_me, 'москва', WordStatus.accepted),
      );
      expect(connection.sent.last, const WordMsg('Москва'));
    });

    test('sendWord ends without a verdict when the game is over', () async {
      await startGame();

      final verdict = client.sendWord('москва');
      connection.receive(
        const GameOver(
          reason: GameOverReason.timeout,
          loser: _me,
          words: 0,
          durationSec: 30,
        ),
      );

      expect(await verdict, isNull);
    });

    test('sendWord ends without a verdict on a protocol error', () async {
      await startGame();

      final verdict = client.sendWord('москва');
      connection.receive(const ProtocolError('invalid_state'));

      expect(await verdict, isNull);
    });

    test('leaving while the opponent moves ends that move', () async {
      final (config, _) = await startGame();
      final move = expectLater(
        opponent(config).onCreateWord('а'),
        throwsA(
          isA<SurrenderException>().having(
            (e) => e.target,
            'target',
            same(owner(config)),
          ),
        ),
      );

      await opponent(config).close();

      await move;
    });

    test('a lost socket ends the game as a disconnect of the owner', () async {
      final (config, events) = await startGame();

      connection.drop();
      await pumpEventQueue();

      expect(
        events.single,
        isA<OnMoveFinished>()
            .having((e) => e.endType, 'endType', MoveFinishType.disconnected)
            .having(
              (e) => e.finishRequester,
              'finishRequester',
              same(owner(config)),
            ),
      );
    });

    test(
      'replaced ends the game, rate_limited and invalid_state do not',
      () async {
        final (config, events) = await startGame();

        connection
          ..receive(const ProtocolError('rate_limited'))
          ..receive(const ProtocolError('invalid_state'));
        await pumpEventQueue();
        expect(events, isEmpty);

        connection.receive(const ProtocolError('replaced'));
        await pumpEventQueue();

        expect(
          events.single,
          isA<OnMoveFinished>()
              .having((e) => e.endType, 'endType', MoveFinishType.disconnected)
              .having(
                (e) => e.finishRequester,
                'finishRequester',
                same(owner(config)),
              ),
        );
      },
    );

    test('closing the opponent mid-game leaves, socket stays', () async {
      final (config, _) = await startGame();

      await opponent(config).close();

      expect(connection.sent.whereType<Leave>(), hasLength(1));
      expect(connection.isConnected, isTrue);
    });

    test('leave is sent once', () async {
      final (config, _) = await startGame();

      client.leave();
      client.leave();
      await opponent(config).close();

      expect(connection.sent.whereType<Leave>(), hasLength(1));
    });

    test('closing the opponent after gameOver sends nothing', () async {
      final (config, _) = await startGame();
      connection.receive(
        const GameOver(
          reason: GameOverReason.surrender,
          loser: _opponentId,
          words: 2,
          durationSec: 20,
        ),
      );
      await pumpEventQueue();

      await opponent(config).close();

      expect(connection.sent.whereType<Leave>(), isEmpty);
    });
  });
}
