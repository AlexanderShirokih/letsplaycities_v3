// Plain `test()` only: the binding of `testWidgets` answers every HttpClient
// request with 400, which would break the real WebSockets here.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/routes/routes.dart';
import 'package:lets_play_cities/remote/server/server_connection.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

const _wait = Duration(seconds: 5);

/// Time of the host that moves only by [advance]
class _FakeClock implements HostClock {
  DateTime _now = DateTime(2026, 11, 9, 12);
  final _timers = <_FakeTimer>[];

  @override
  DateTime now() => _now;

  @override
  Timer startTimer(Duration duration, void Function() callback) {
    final timer = _FakeTimer(_now.add(duration), callback, _timers);
    _timers.add(timer);

    return timer;
  }

  /// Moves the time by [duration] and runs the timers that became due
  void advance(Duration duration) {
    final target = _now.add(duration);

    while (true) {
      final due = _timers.where((t) => !t.at.isAfter(target)).toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;

      final timer = due.first;
      _timers.remove(timer);
      _now = timer.at;
      timer.callback();
    }

    _now = target;
  }
}

class _FakeTimer implements Timer {
  final DateTime at;
  final void Function() callback;
  final List<_FakeTimer> _owner;

  _FakeTimer(this.at, this.callback, this._owner);

  @override
  void cancel() => _owner.remove(this);

  @override
  bool get isActive => _owner.contains(this);

  @override
  int get tick => 0;
}

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) {}
}

/// A player of the LAN host over its own [GameConnection]
class _Client {
  final GameConnection connection;
  final _received = <ServerGameMessage>[];
  final closes = <GameConnectionClose>[];
  Completer<void>? _arrival;
  late final LpsUser me;

  _Client(this.connection) {
    connection.messages.listen((message) {
      _received.add(message);
      _arrival?.complete();
      _arrival = null;
    });
    connection.closes.listen(closes.add);
  }

  static Future<_Client> open(String url, String name) async {
    final client = _Client(
      GameConnection(
        url: url,
        headers: () async => const {},
        clientName: 'lps-test/1',
        playerName: () => name,
      ),
    );
    client.me = await client.connection.ensureConnected();
    expect(await client.next(), isA<Welcome>());

    return client;
  }

  int get id => me.id;

  void send(ClientGameMessage message) => connection.send(message);

  /// The next message of the host
  Future<ServerGameMessage> next() async {
    while (_received.isEmpty) {
      await (_arrival ??= Completer<void>()).future.timeout(_wait);
    }

    return _received.removeAt(0);
  }

  /// Fails if a message is waiting
  Future<void> expectNothing() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(_received, isEmpty);
  }
}

void main() {
  late _FakeClock clock;
  late _RecordingLogger logger;
  late WebSocketServerConnection server;
  late ServerGameControllerImpl controller;
  late Future<void> running;
  late String url;
  var moveTimeSec = 0;

  final clients = <_Client>[];

  setUp(() async {
    clock = _FakeClock();
    logger = _RecordingLogger();
    moveTimeSec = 0;
    server = WebSocketServerConnection(
      RequestDispatcher.buildRequestDispatcher(logger),
      port: 0,
      address: InternetAddress.loopbackIPv4,
    );
    controller = ServerGameControllerImpl(
      server,
      () => LocalGameServer(
        moveTimeSec: () => moveTimeSec,
        defaultPlayerName: 'Игрок',
        logger: logger,
        clock: clock,
      ),
    );
    await controller.setUp();
    running = controller.runGame();
    url = 'ws://127.0.0.1:${server.port}/v1/game';
  });

  tearDown(() async {
    for (final client in clients) {
      await client.connection.close();
    }
    clients.clear();
    await controller.close();
    await running.timeout(_wait);
  });

  Future<_Client> join(String name) async {
    final client = await _Client.open(url, name);
    clients.add(client);

    return client;
  }

  /// Two players in a game; [first] moves first
  Future<(_Client, _Client)> match() async {
    final first = await join('Alice');
    final second = await join('Bob');

    first.send(const Find());
    expect(await first.next(), const Queued());
    second.send(const Find());
    expect(await second.next(), const Queued());

    expect(await first.next(), isA<Match>());
    expect(await second.next(), isA<Match>());

    return (first, second);
  }

  /// Sends [word] from [author] and expects both to hear it accepted
  Future<void> accepted(_Client author, _Client other, String word) async {
    author.send(WordMsg(word));
    final verdict = WordResultMsg(
      author.id,
      word.toLowerCase(),
      WordStatus.accepted,
    );
    expect(await author.next(), verdict);
    expect(await other.next(), verdict);
  }

  test('two clients play to gameOver over the LAN host', () async {
    final alice = await join('Alice');
    final bob = await join('Bob');

    expect(alice.me.id, 1);
    expect(alice.me.name, 'Alice');
    expect(alice.me.provider, 'lan');
    expect(alice.me.avatarHash, isNull);
    expect(alice.me.lastSeenAt, clock.now());
    expect(bob.me.id, 2);
    expect(bob.me.name, 'Bob');

    alice.send(const Find());
    expect(await alice.next(), const Queued());
    bob.send(const Find());
    expect(await bob.next(), const Queued());

    final aliceMatch = await alice.next() as Match;
    final bobMatch = await bob.next() as Match;
    expect(aliceMatch.youStart, isTrue);
    expect(bobMatch.youStart, isFalse);
    expect(aliceMatch.gameId, bobMatch.gameId);
    // «Таймер хода» of the host is off: the default move time
    expect(aliceMatch.moveTimeSec, 92);
    expect(
      aliceMatch.opponent,
      const MatchOpponent(id: 2, name: 'Bob', friendship: Friendship.none),
    );
    expect(
      bobMatch.opponent,
      const MatchOpponent(id: 1, name: 'Alice', friendship: Friendship.none),
    );

    // The host keeps the words as formatCity does
    alice.send(const WordMsg('  Москва '));
    const moscow = WordResultMsg(1, 'москва', WordStatus.accepted);
    expect(await alice.next(), moscow);
    expect(await bob.next(), moscow);

    await accepted(bob, alice, 'анапа');

    alice.send(const ChatMsg('привет'));
    expect(await bob.next(), const ChatIn(1, 'привет'));
    alice.send(ChatMsg('я' * 201));
    expect(await alice.next(), const ProtocolError(ProtocolError.badMessage));
    await bob.expectNothing();

    clock.advance(const Duration(seconds: 3));
    alice.send(const Leave());
    const over = GameOver(
      reason: GameOverReason.surrender,
      loser: 1,
      words: 2,
      durationSec: 3,
    );
    expect(await alice.next(), over);
    expect(await bob.next(), over);

    // Both are free again: another game can start
    alice.send(const Find());
    expect(await alice.next(), const Queued());
    bob.send(const Find());
    expect(await bob.next(), const Queued());
    expect(await alice.next(), isA<Match>());
    expect(await bob.next(), isA<Match>());
    expect(logger.errors, isEmpty);
  });

  test('the move time is the time limit of the host', () async {
    moveTimeSec = 30;

    final first = await join('Alice');
    final second = await join('Bob');
    first.send(const Find());
    second.send(const Find());
    await first.next();
    await second.next();

    expect((await first.next() as Match).moveTimeSec, 30);
    expect((await second.next() as Match).moveTimeSec, 30);
  });

  test(
    'wrong letter and already used are rejected only to the author',
    () async {
      final (alice, bob) = await match();

      bob.send(const WordMsg('бали'));
      expect(
        await bob.next(),
        const WordResultMsg(2, 'бали', WordStatus.notYourTurn),
      );

      await accepted(alice, bob, 'анапа');

      bob.send(const WordMsg('бали'));
      expect(
        await bob.next(),
        const WordResultMsg(2, 'бали', WordStatus.wrongLetter),
      );

      bob.send(const WordMsg('Анапа'));
      expect(
        await bob.next(),
        const WordResultMsg(2, 'анапа', WordStatus.alreadyUsed),
      );

      // Alice heard none of the rejections: her next message is Bob's move
      await alice.expectNothing();
      await accepted(bob, alice, 'абакан');

      // The letter skips the endings «ь ъ ы ё»
      await accepted(alice, bob, 'нарьян-мар');
      await accepted(bob, alice, 'рыбинск');
      await accepted(alice, bob, 'камышлы');
      bob.send(const WordMsg('ыргыз'));
      expect(
        await bob.next(),
        const WordResultMsg(2, 'ыргыз', WordStatus.wrongLetter),
      );
      await accepted(bob, alice, 'луга');
    },
  );

  test('timeout ends the game with the mover as loser', () async {
    moveTimeSec = 30;
    final (alice, bob) = await match();

    clock.advance(const Duration(seconds: 20));
    await accepted(alice, bob, 'анапа');

    // The accepted word restarted the timer of the move
    clock.advance(const Duration(seconds: 20));
    await alice.expectNothing();

    clock.advance(const Duration(seconds: 10));
    const over = GameOver(
      reason: GameOverReason.timeout,
      loser: 2,
      words: 1,
      durationSec: 50,
    );
    expect(await alice.next(), over);
    expect(await bob.next(), over);

    // The game is over: a late word is out of place
    bob.send(const WordMsg('абакан'));
    expect(await bob.next(), const ProtocolError(ProtocolError.invalidState));
  });

  test('leave gives surrender', () async {
    final (alice, bob) = await match();

    bob.send(const Leave());
    const over = GameOver(
      reason: GameOverReason.surrender,
      loser: 2,
      words: 0,
      durationSec: 0,
    );
    expect(await alice.next(), over);
    expect(await bob.next(), over);
  });

  test('disconnect gives opponentLeft', () async {
    final (alice, bob) = await match();

    await accepted(alice, bob, 'анапа');
    await bob.connection.close();

    expect(
      await alice.next(),
      const GameOver(
        reason: GameOverReason.opponentLeft,
        loser: 2,
        words: 1,
        durationSec: 0,
      ),
    );
    expect(alice.closes, isEmpty);
  });

  test('invite answers invalid_state', () async {
    final alice = await join('Alice');

    alice.send(const Invite(2));
    expect(await alice.next(), const ProtocolError(ProtocolError.invalidState));

    alice.send(const InviteReply(2, accept: true));
    expect(await alice.next(), const ProtocolError(ProtocolError.invalidState));
  });

  test('messages out of their state answer invalid_state', () async {
    final alice = await join('Alice');

    for (final message in [
      const WordMsg('анапа'),
      const ChatMsg('привет'),
      const Leave(),
      const Cancel(),
      const Hello(protocol: 1, client: 'again'),
    ]) {
      alice.send(message);
      expect(
        await alice.next(),
        const ProtocolError(ProtocolError.invalidState),
        reason: '$message',
      );
    }

    alice.send(const Find());
    expect(await alice.next(), const Queued());
    alice.send(const Find());
    expect(await alice.next(), const ProtocolError(ProtocolError.invalidState));

    // Leaving the queue: a later player waits instead of playing Alice
    alice.send(const Cancel());
    await alice.expectNothing();
    final bob = await join('Bob');
    bob.send(const Find());
    expect(await bob.next(), const Queued());
    await bob.expectNothing();
  });

  test('an empty name gets the default one', () async {
    final player = await join('  ');

    expect(player.me.name, 'Игрок');
  });

  test('a third player cannot join a full host', () async {
    await join('Alice');
    await join('Bob');

    // Closed with an error instead of waiting for a welcome
    final third = GameConnection(
      url: url,
      headers: () async => const {},
      clientName: 'lps-test/1',
      playerName: () => 'Carol',
    );

    await expectLater(
      third.ensureConnected(),
      throwsA(
        isA<ProtocolErrorException>().having(
          (e) => e.code,
          'code',
          ProtocolError.invalidState,
        ),
      ),
    );
  });

  test('a player that left frees the place', () async {
    final alice = await join('Alice');
    await join('Bob');
    await alice.connection.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final carol = await join('Carol');
    expect(carol.me.id, 3);
  });

  test('a malformed frame gets bad_message and keeps the socket', () async {
    final socket = await WebSocket.connect(url);
    final frames = StreamIterator(socket.cast<String>());
    Future<Map<String, dynamic>> nextFrame() async {
      expect(await frames.moveNext().timeout(_wait), isTrue);

      return jsonDecode(frames.current) as Map<String, dynamic>;
    }

    socket.add(jsonEncode({'type': 'find'}));
    expect(await nextFrame(), {'type': 'error', 'code': 'hello_required'});

    for (final frame in [
      'not json',
      '[1, 2]',
      jsonEncode({'type': 'dance'}),
      jsonEncode({'type': 'hello', 'protocol': 'one'}),
    ]) {
      socket.add(frame);
      expect(await nextFrame(), {
        'type': 'error',
        'code': 'bad_message',
      }, reason: frame);
    }

    socket.add(
      jsonEncode({
        'type': 'hello',
        'protocol': 1,
        'client': 'raw',
        'name': 'R',
      }),
    );
    expect((await nextFrame())['type'], 'welcome');

    await socket.close();
    expect(logger.errors, isEmpty);
  });

  test('a hello of another protocol is refused and closed', () async {
    final socket = await WebSocket.connect(url);
    final frames = <String>[];
    final done = socket.cast<String>().forEach(frames.add);

    socket.add(jsonEncode({'type': 'hello', 'protocol': 2, 'client': 'raw'}));
    await done.timeout(_wait);

    expect(frames.map(jsonDecode), [
      {'type': 'error', 'code': 'unsupported_protocol'},
    ]);
    expect(socket.closeCode, 1008);
  });

  test('closing the host ends the game and closes every socket', () async {
    final (alice, bob) = await match();

    await controller.close();
    await running.timeout(_wait);

    expect(
      await alice.next(),
      const GameOver(
        reason: GameOverReason.opponentLeft,
        loser: 2,
        words: 0,
        durationSec: 0,
      ),
    );
    expect(
      await bob.next(),
      const GameOver(
        reason: GameOverReason.opponentLeft,
        loser: 1,
        words: 0,
        durationSec: 0,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(alice.closes, hasLength(1));
    expect(bob.closes, hasLength(1));
    expect(controller.isRunning, isFalse);
  });
}
