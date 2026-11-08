import 'dart:async';
import 'dart:developer' as developer;

import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/handlers/network_interceptor.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/remote/remote_player.dart';

/// Plays on the game server over the shared [GameConnection]: finds an
/// opponent or invites a friend, then plays the game the server judges.
class RemoteGameClient {
  /// The longest chat message the server accepts, in code points
  static const maxChatLength = 200;

  final GameConnection _connection;

  /// Whether the server is a LAN host rather than the main server: a local
  /// game is played in [GameMode.multiplayer] instead of [GameMode.network].
  final bool isLocal;

  /// The server of the avatars, also in a LAN game; `null` shows no avatars
  final AppConfig? _pictureConfig;

  /// Whether the player wants the chat
  final bool _chatEnabled;

  /// The user the server welcomed
  LpsUser? _me;

  /// The game of the last [configFor]
  RemoteGame? _game;

  RemoteGameClient(
    this._connection, {
    required this.isLocal,
    this._pictureConfig,
    this._chatEnabled = true,
  });

  /// Opens the connection unless it is open. Returns the user that the
  /// server welcomed.
  Future<LpsUser> connect() async => _me = await _connection.ensureConnected();

  /// Enters the queue of random matching
  Future<void> find() => _sendWhenConnected(const Find());

  /// Invites friend [userId]
  Future<void> invite(int userId) => _sendWhenConnected(Invite(userId));

  /// Answers the invitation of [userId]
  Future<void> reply(int userId, bool accept) =>
      _sendWhenConnected(InviteReply(userId, accept: accept));

  Future<void> _sendWhenConnected(ClientGameMessage message) async {
    await connect();

    _connection.send(message);
  }

  /// Leaves the queue or withdraws the invitation. Does nothing without a
  /// connection or while a game runs.
  void cancel() {
    if (!_connection.isConnected || _game?.isRunning == true) return;

    _connection.send(const Cancel());
  }

  /// What the server says while the client waits: listen before [find],
  /// [invite] or [reply], the connection keeps nothing for later listeners.
  Stream<WaitingEvent> get waiting =>
      _connection.messages.where((m) => m is WaitingEvent).cast<WaitingEvent>();

  /// Emits each time the connection ends
  Stream<GameConnectionClose> get closes => _connection.closes;

  /// The game that [match] starts. Call it as soon as the match arrives:
  /// from then on the game keeps the moves and messages of the server until
  /// the game screen reads them.
  GameConfig configFor(Match match) {
    final me = _me;
    if (me == null) {
      throw StateError('The match came before the welcome of the server');
    }

    _game?._release();

    final owner = Player(
      RemoteAccount(
        me,
        avatarUrl: _avatarUrl(me.id, me.avatarHash),
        canReceiveMessages: _chatEnabled,
      ),
    );
    final game = _game = RemoteGame._(_connection, me.id, owner);
    final opponent = RemotePlayer(
      AdvancedAccountInfo(
        BaseProfileInfo(
          userId: match.opponent.id,
          login: match.opponent.name,
          pictureUrl: _avatarUrl(match.opponent.id, match.opponent.avatarHash),
        ),
        true,
      ),
      game,
    );
    game._start(opponent);

    return GameConfig(
      gameMode: isLocal ? GameMode.multiplayer : GameMode.network,
      usersListOverride: UsersList(
        match.youStart ? [owner, opponent] : [opponent, owner],
      ),
      timeLimitOverride: match.moveTimeSec,
      externalEventSource: (_) => game._events.stream,
      additionalEventHandlers: [NetworkInterceptor(this)],
    );
  }

  String? _avatarUrl(int id, String? hash) {
    final config = _pictureConfig;

    return config == null ? null : avatarUrlOf(config, id, hash);
  }

  /// Sends the own [word] and returns the verdict of the server on it, or
  /// `null` when the game ended first
  Future<WordResultMsg?> sendWord(String word) async =>
      await _game?._sendWord(word);

  /// Sends a chat message, cut to [maxChatLength] characters
  void sendChat(String text) => _game?._send(
    ChatMsg(String.fromCharCodes(text.runes.take(maxChatLength))),
  );

  /// Surrenders the running game; the server answers with `gameOver`. Throws
  /// [RemoteIOException] when the connection is lost.
  void leave() => _game?._leave();
}

/// One game on the server: keeps what the server says about it from the
/// match until the game ends
class RemoteGame {
  final GameConnection _connection;
  final int _me;
  final Player _owner;
  late final RemotePlayer _opponent;

  /// Chat messages and the end of the game, kept until the game reads them
  final _events = StreamController<GameEvent>();

  /// Words of the opponent that no move has taken yet
  final _opponentWords = <String>[];
  Completer<String>? _nextWord;

  final _ended = Completer<void>();
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _leaveSent = false;

  RemoteGame._(this._connection, this._me, this._owner);

  void _start(RemotePlayer opponent) {
    _opponent = opponent;
    _subscriptions
      ..add(_connection.messages.listen(_onMessage))
      ..add(_connection.closes.listen((_) => _lose()));
  }

  /// `false` once the game is over
  bool get isRunning => !_ended.isCompleted;

  int get _opponentId =>
      (_opponent.accountInfo as AdvancedAccountInfo).profileInfo.userId;

  void _onMessage(ServerGameMessage message) {
    switch (message) {
      case WordResultMsg(:final by, :final text, :final status)
          when by == _opponentId && status == WordStatus.accepted:
        _addOpponentWord(text);
      case ChatIn(:final by, :final text) when by == _opponentId:
        _events.add(MessageEvent(text, _opponent));
      case GameOver(:final reason, :final loser):
        _end(
          OnMoveFinished(switch (reason) {
            GameOverReason.timeout => MoveFinishType.timeout,
            GameOverReason.surrender => MoveFinishType.surrender,
            GameOverReason.opponentLeft => MoveFinishType.disconnected,
          }, loser == _opponentId ? _opponent : _owner),
        );
      case ProtocolError(code: 'replaced'):
        // Another device signed in: the server counts the game as lost
        _lose();
      case ProtocolError(:final code):
        developer.log('Game server error: $code', name: 'RemoteGame');
      default:
        break;
    }
  }

  void _addOpponentWord(String word) {
    final next = _nextWord;
    if (next != null) {
      _nextWord = null;
      next.complete(word);
    } else {
      _opponentWords.add(word);
    }
  }

  /// The next word that the server accepted from the opponent
  Future<String> nextOpponentWord() {
    if (_opponentWords.isNotEmpty) {
      return Future.value(_opponentWords.removeAt(0));
    }

    return (_nextWord ??= Completer<String>()).future;
  }

  /// The connection is gone: the server counts the game as lost
  void _lose() => _end(OnMoveFinished(MoveFinishType.disconnected, _owner));

  void _end(OnMoveFinished finish) {
    if (!isRunning) return;

    _events.add(finish);
    _release();
  }

  /// Stops listening to the connection, which outlives the game
  void _release() {
    if (!_ended.isCompleted) _ended.complete();

    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_events.close());
  }

  Future<WordResultMsg?> _sendWord(String word) async {
    if (!isRunning) return null;

    final verdict = Completer<WordResultMsg?>();
    final subscription = _connection.messages.listen((message) {
      if (message is WordResultMsg &&
          message.by == _me &&
          !verdict.isCompleted) {
        verdict.complete(message);
      }
    });
    unawaited(
      _ended.future.then((_) {
        if (!verdict.isCompleted) verdict.complete(null);
      }),
    );

    try {
      _connection.send(WordMsg(word));

      return await verdict.future;
    } on RemoteIOException {
      _lose();

      return null;
    } finally {
      await subscription.cancel();
    }
  }

  void _send(ClientGameMessage message) {
    if (!isRunning) return;

    try {
      _connection.send(message);
    } on RemoteIOException {
      _lose();
    }
  }

  void _leave() {
    if (!isRunning || _leaveSent) return;

    _connection.send(const Leave());
    _leaveSent = true;
  }

  /// Leaves the game unless it is over and stops listening to it. The
  /// connection stays open for the next game.
  Future<void> quit() async {
    if (isRunning) {
      try {
        _leave();
      } on RemoteIOException {
        // The server ends the game of a lost connection itself
      }
    }

    _release();
  }
}
