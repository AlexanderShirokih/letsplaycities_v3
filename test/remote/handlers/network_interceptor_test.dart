@Timeout(Duration(seconds: 5))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/handlers/network_interceptor.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/remote/remote_player.dart';

import '../fake_game_connection.dart';

const _me = 1;
const _opponentId = 2;

void main() {
  late FakeGameConnection connection;
  late NetworkInterceptor interceptor;
  late Player player;
  late RemotePlayer opponent;

  setUp(() async {
    connection = FakeGameConnection();
    final client = RemoteGameClient(connection, isLocal: false);
    await client.find();
    final config = client.configFor(
      const Match(
        gameId: 5,
        opponent: MatchOpponent(
          id: _opponentId,
          name: 'Пётр',
          friendship: Friendship.none,
        ),
        youStart: true,
        moveTimeSec: 30,
      ),
    );
    interceptor = config.additionalEventHandlers!
        .whereType<NetworkInterceptor>()
        .single;
    player = config.usersListOverride!.all.whereType<Player>().single;
    opponent = config.usersListOverride!.all.whereType<RemotePlayer>().single;
    connection.sent.clear();
  });

  /// Sends the own [word] and answers it with [status] and [text]
  Future<List<GameEvent>> verdictOn(
    String word,
    WordStatus status, {
    String? text,
  }) async {
    final result = interceptor.process(Accepted(word, player)).toList();
    await pumpEventQueue();
    connection.receive(WordResultMsg(_me, text ?? word, status));

    return result;
  }

  test('own word is sent and the server text is the word of record', () async {
    final events = await verdictOn(
      'Москва ',
      WordStatus.accepted,
      text: 'москва',
    );

    expect(connection.sent, [const WordMsg('Москва ')]);
    expect(
      events.single,
      isA<Accepted>()
          .having((e) => e.word, 'word', 'москва')
          .having((e) => e.owner, 'owner', same(player)),
    );
  });

  test('wrongLetter maps to WrongLetter with last suitable char', () async {
    await interceptor.process(const OnFirstCharChanged('а')).toList();

    final events = await verdictOn('москва', WordStatus.wrongLetter);

    expect(
      events.single,
      isA<WrongLetter>().having((e) => e.validLetter, 'validLetter', 'а'),
    );
  });

  test('rejections map to word checking results', () async {
    expect(
      (await verdictOn('москва', WordStatus.alreadyUsed)).single,
      isA<AlreadyUsed>().having((e) => e.word, 'word', 'москва'),
    );
    expect(
      (await verdictOn('масква', WordStatus.unknown)).single,
      isA<NotFound>().having((e) => e.word, 'word', 'масква'),
    );
    expect(
      (await verdictOn('москва', WordStatus.notYourTurn)).single,
      isA<Error>().having(
        (e) => e.exception,
        'exception',
        isA<WrongMoveException>(),
      ),
    );
  });

  test('opponent words pass without a request', () async {
    final accepted = Accepted('анапа', opponent);

    final events = await interceptor.process(accepted).toList();

    expect(events, [same(accepted)]);
    expect(connection.sent, isEmpty);
  });

  test('own chat is sent and passed on', () async {
    final message = MessageEvent('привет', player);

    final events = await interceptor.process(message).toList();

    expect(events, [same(message)]);
    expect(connection.sent, [const ChatMsg('привет')]);
  });

  test('a leave request sends leave and goes no further', () async {
    final events = await interceptor.process(LeaveRequested(player)).toList();

    expect(events, isEmpty);
    expect(connection.sent, [const Leave()]);
  });

  test('a leave that cannot be sent ends the game as surrender', () async {
    await connection.close();

    final events = await interceptor.process(LeaveRequested(player)).toList();

    expect(
      events.single,
      isA<OnMoveFinished>()
          .having((e) => e.endType, 'endType', MoveFinishType.surrender)
          .having((e) => e.finishRequester, 'finishRequester', same(player)),
    );
  });
}
