import 'dart:async';
import 'dart:io';

import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_message_codec.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/remote/server/client_failure_logging.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Time of the LAN host
abstract class HostClock {
  DateTime now();

  /// Calls [callback] once after [duration]
  Timer startTimer(Duration duration, void Function() callback);
}

/// The time of the device
class SystemHostClock implements HostClock {
  const SystemHostClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Timer startTimer(Duration duration, void Function() callback) =>
      Timer(duration, callback);
}

/// The game server of protocol v1 in the local network: `hello`/`welcome`,
/// `find`/`queued`/`match` for two players, the moves, the move timer, the
/// chat, `leave` and `gameOver`. It has no dictionary: the clients check a
/// word against theirs before they send it, so it never answers `unknown`
/// to a city. It has no friends either: invitations get `invalid_state`.
class LocalGameServer {
  /// The move time when the time limit of the host is off
  static const defaultMoveTimeSec = 92;

  /// Players that the host welcomes at a time
  static const maxPlayers = 2;

  /// The longest chat message, in code points
  static const maxChatLength = 200;

  /// The `provider` of the users of the host
  static const provider = 'lan';

  /// The time limit of the host in seconds, 0 when it is off
  final int Function() _moveTimeSec;

  /// The name of a player who said `hello` without one
  final String _defaultPlayerName;
  final ErrorLogger _logger;
  final HostClock _clock;
  final _codec = const GameMessageCodec();

  /// Every open socket, also before its `hello`
  final _sessions = <_Session>{};
  final _queue = <_Session>[];

  var _lastUserId = 0;
  var _lastGameId = 0;
  var _closed = false;

  LocalGameServer({
    required this._moveTimeSec,
    required this._defaultPlayerName,
    required this._logger,
    this._clock = const SystemHostClock(),
  });

  /// Plays with the client of [socket] until the socket ends
  void serve(WebSocket socket) {
    final session = _Session(socket, _codec);

    if (_closed) {
      unawaited(session.close(WebSocketStatus.goingAway, 'closed'));

      return;
    }

    _sessions.add(session);
    socket.listen(
      (frame) => _onFrame(session, frame),
      onError: (Object e, StackTrace s) =>
          _logger.clientFailure('LAN game socket failed', e, s),
      onDone: () => _onDisconnect(session),
    );
  }

  /// Ends the running games, the opponent of each player being the one who
  /// left, and closes every socket
  Future<void> close() async {
    _closed = true;

    final sessions = List.of(_sessions);
    _sessions.clear();
    _queue.clear();

    for (final session in sessions) {
      session.room?.abort();
    }

    await Future.wait(
      sessions.map((s) => s.close(WebSocketStatus.goingAway, 'closed')),
    );
  }

  void _onFrame(_Session session, Object? frame) {
    try {
      _handle(session, frame);
    } catch (e, s) {
      // One broken message must not stop the host
      _logger.error(e, s);
    }
  }

  void _handle(_Session session, Object? frame) {
    final ClientGameMessage message;
    try {
      if (frame is! String) {
        throw const FormatException('A binary frame');
      }

      message = _codec.decodeClient(frame);
    } on FormatException catch (e) {
      _logger.log('A LAN client sent a bad message: ${e.message}');
      session.send(const ProtocolError(ProtocolError.badMessage));

      return;
    }

    if (session.user == null) {
      if (message is Hello) {
        _hello(session, message);
      } else {
        session.send(const ProtocolError(ProtocolError.helloRequired));
      }

      return;
    }

    final room = session.room;

    switch (message) {
      case Find() when session.isIdle:
        _find(session);
      case Cancel() when session.isQueued:
        _queue.remove(session);
        session.isQueued = false;
      case WordMsg(:final text) when room != null:
        room.word(session, text);
      case ChatMsg(:final text) when room != null:
        if (text.runes.length > maxChatLength) {
          session.send(const ProtocolError(ProtocolError.badMessage));
        } else {
          room.chat(session, text);
        }
      case Leave() when room != null:
        room.finish(GameOverReason.surrender, loser: session);
      default:
        // A second hello, an invitation, a request of the wrong state
        session.send(const ProtocolError(ProtocolError.invalidState));
    }
  }

  void _hello(_Session session, Hello hello) {
    if (hello.protocol != GameConnection.protocolVersion) {
      session.send(const ProtocolError(ProtocolError.unsupportedProtocol));
      unawaited(
        session.close(
          WebSocketStatus.policyViolation,
          ProtocolError.unsupportedProtocol,
        ),
      );

      return;
    }

    final players = _sessions.where((s) => s.user != null).length;
    if (players >= maxPlayers) {
      // The game of this host is full
      session.send(const ProtocolError(ProtocolError.invalidState));
      unawaited(session.close(WebSocketStatus.policyViolation, 'full'));

      return;
    }

    final name = hello.name.trim();
    final user = session.user = LpsUser(
      id: ++_lastUserId,
      name: name.isEmpty ? _defaultPlayerName : name,
      provider: provider,
      lastSeenAt: _clock.now(),
    );

    session.send(Welcome(user));
  }

  void _find(_Session session) {
    session.isQueued = true;
    _queue.add(session);
    session.send(const Queued());

    if (_queue.length < 2) return;

    // The one who came first starts
    final starter = _queue.removeAt(0)..isQueued = false;
    final invited = _queue.removeAt(0)..isQueued = false;
    final moveTimeSec = _moveTimeSec();

    _Room(
      id: ++_lastGameId,
      starter: starter,
      invited: invited,
      moveTimeSec: moveTimeSec > 0 ? moveTimeSec : defaultMoveTimeSec,
      clock: _clock,
    ).start();
  }

  void _onDisconnect(_Session session) {
    _sessions.remove(session);
    _queue.remove(session);
    session.room?.finish(GameOverReason.opponentLeft, loser: session);
  }
}

/// One socket of the host
class _Session {
  final WebSocket _socket;
  final GameMessageCodec _codec;

  /// The user of the `welcome`, `null` before it
  LpsUser? user;
  bool isQueued = false;

  /// The game the user plays
  _Room? room;

  _Session(this._socket, this._codec);

  int get id => user!.id;

  bool get isIdle => !isQueued && room == null;

  void send(ServerGameMessage message) {
    if (_socket.readyState != WebSocket.open) return;

    try {
      _socket.add(_codec.encodeServer(message));
    } on StateError {
      // The socket closed meanwhile; its end is handled by the host
    }
  }

  /// Closes the socket; does not wait long for a client that does not answer
  Future<void> close(int code, String reason) async {
    try {
      await _socket.close(code, reason).timeout(const Duration(seconds: 1));
    } catch (_) {
      // The client is gone or does not answer
    }
  }
}

/// One game: the turn, the words, the move timer
class _Room {
  final int id;

  /// [_seats] first starts
  final List<_Session> _seats;
  final int moveTimeSec;
  final HostClock _clock;

  final _used = <String>{};
  var _last = '';
  var _turn = 0;
  var _words = 0;
  late final DateTime _startedAt;
  Timer? _timer;
  var _finished = false;

  _Room({
    required this.id,
    required _Session starter,
    required _Session invited,
    required this.moveTimeSec,
    required this._clock,
  }) : _seats = [starter, invited];

  void start() {
    _startedAt = _clock.now();

    for (final (index, seat) in _seats.indexed) {
      final opponent = _opponentOf(seat).user!;
      seat
        ..room = this
        ..send(
          Match(
            gameId: id,
            opponent: MatchOpponent(
              id: opponent.id,
              name: opponent.name,
              friendship: Friendship.none,
            ),
            youStart: index == 0,
            moveTimeSec: moveTimeSec,
          ),
        );
    }

    _armTimer();
  }

  _Session _opponentOf(_Session seat) =>
      seat == _seats.first ? _seats.last : _seats.first;

  void word(_Session author, String text) {
    if (_finished) return;

    final word = formatCity(text);
    final status = _check(author, word);

    if (status != WordStatus.accepted) {
      // Only the author hears a rejected word
      author.send(WordResultMsg(author.id, word, status));

      return;
    }

    _used.add(word);
    _last = word;
    _words++;
    _turn = 1 - _seats.indexOf(author);

    _sendToBoth(WordResultMsg(author.id, word, WordStatus.accepted));
    _armTimer();
  }

  WordStatus _check(_Session author, String word) {
    if (_seats[_turn] != author) return WordStatus.notYourTurn;

    // Not a city at all; the clients never send it
    if (word.isEmpty) return WordStatus.unknown;

    if (_last.isNotEmpty && word[0] != findLastSuitableChar(_last)) {
      return WordStatus.wrongLetter;
    }

    if (_used.contains(word)) return WordStatus.alreadyUsed;

    return WordStatus.accepted;
  }

  void chat(_Session author, String text) {
    if (_finished) return;

    _opponentOf(author).send(ChatIn(author.id, text));
  }

  /// Ends the game that [loser] lost
  void finish(GameOverReason reason, {required _Session loser}) {
    if (!_end()) return;

    _sendToBoth(_gameOver(reason, loser));
  }

  /// Ends the game because the host closes: each player hears that the
  /// opponent left
  void abort() {
    if (!_end()) return;

    for (final seat in _seats) {
      seat.send(_gameOver(GameOverReason.opponentLeft, _opponentOf(seat)));
    }
  }

  /// Returns `false` if the game is already over
  bool _end() {
    if (_finished) return false;

    _finished = true;
    _timer?.cancel();

    for (final seat in _seats) {
      seat.room = null;
    }

    return true;
  }

  GameOver _gameOver(GameOverReason reason, _Session loser) => GameOver(
    reason: reason,
    loser: loser.id,
    words: _words,
    durationSec: _clock.now().difference(_startedAt).inSeconds,
  );

  void _sendToBoth(ServerGameMessage message) {
    for (final seat in _seats) {
      seat.send(message);
    }
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = _clock.startTimer(
      Duration(seconds: moveTimeSec),
      () => finish(GameOverReason.timeout, loser: _seats[_turn]),
    );
  }
}
