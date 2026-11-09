import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart'
    as protocol;

part 'waiting_room_event.dart';
part 'waiting_room_state.dart';

/// Finds an opponent or invites a friend over the shared game connection
/// and hands the game of the match to the screen.
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState>
    with SequentialEventMapping<WaitingRoomEvent, WaitingRoomState> {
  final RemoteGameClient _gameClient;
  final DateTime Function() _clock;

  WaitingRoomBloc(this._gameClient, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const Idle()) {
    mapEventsSequentially(_mapEventToState);
  }

  /// Set as soon as [close] starts: the answers of the server that still
  /// come are dropped.
  bool _closing = false;

  /// Number of the current request. Each new request, cancel and end of a
  /// request changes it, so the answers to an older one are dropped.
  int _request = 0;

  /// A find, invitation or accepted invitation is on the server
  bool _requestSent = false;

  /// The match arrived and built a game that no [Starting] handed over yet
  bool _matchPending = false;

  /// Listen to the server while a request waits
  StreamSubscription<Object?>? _waiting;
  StreamSubscription<Object?>? _closes;

  /// Leaves the queue or withdraws the invitation, or leaves the game of a
  /// match that no screen will play, then closes the connection unless a
  /// game runs on it.
  @override
  Future<void> close() async {
    _closing = true;

    // A match whose game no game screen took: nobody would play it
    if (_matchPending || _gameClient.hasUnclaimedGame) {
      unawaited(_gameClient.quitGame());
    } else if (_requestSent) {
      _withdraw();
    }
    _requestSent = false;
    _matchPending = false;

    // The subscriptions drop every event from now on: no need to wait
    unawaited(_stopListening());
    unawaited(_gameClient.disconnect());

    return super.close();
  }

  /// [add] throws StateError once the bloc is closed, so events that come
  /// from network callbacks are dropped while it is closing.
  void _addIfOpen(WaitingRoomEvent event) {
    if (!_closing && !isClosed) add(event);
  }

  Stream<WaitingRoomState> _mapEventToState(WaitingRoomEvent event) async* {
    switch (event) {
      case FindPressed():
        yield* _startRequest(event, const Connecting());
      case InvitePressed(:final friend):
        // Sending it again would withdraw the push the friend already has
        if (state case Inviting(:final target) when target.id == friend.id) {
          return;
        }

        yield* _startRequest(event, Inviting(friend));
      case ReplyToInvite(:final fromId, accept: false):
        // Not a request of its own: a search that runs goes on
        unawaited(
          _gameClient.reply(fromId, false).catchError((Object e) {
            // The invitation expires on the server anyway
            developer.log('Decline failed: $e', name: 'WaitingRoomBloc');
          }),
        );
      case ReplyToInvite():
        yield* _startRequest(event, const Connecting());
      case CancelPressed():
        _endRequest(withdraw: true);
        yield const Idle();
      case AppPaused():
        final waiting =
            state is Connecting || state is Queued || state is Inviting;
        _endRequest(withdraw: true);
        if (waiting) yield const Idle();

        await _gameClient.disconnect();
      case _Connected(:final request, :final source):
        yield* _send(request, source);
      case _RequestFailed(:final request, :final source, :final error):
        if (request != _request) return;

        _endRequest();
        yield Failed(error, retry: source);
      case _ServerSaid(:final request, :final message):
        if (request != _request) return;

        yield* _onServerSaid(message);
      case _Matched(:final request, :final config):
        _matchPending = false;
        if (request != _request) {
          // The user cancelled while the match was on its way
          unawaited(_gameClient.quitGame());
          return;
        }

        _endRequest();
        yield Starting(config);
        yield const Idle();
      case _Closed(:final request, :final close):
        if (request != _request) return;

        _endRequest();
        yield Failed(switch (close.reason) {
          protocol.ProtocolError.replaced => const ProtocolErrorException(
            protocol.ProtocolError.replaced,
          ),
          // The token is gone: the screen asks to sign in again
          GameConnection.signedOut => const UnauthorizedException(
            401,
            'unauthorized',
          ),
          _ => ConnectionException(
            'The game connection closed: ${close.code} ${close.reason}',
          ),
        }, retry: _source);
    }
  }

  /// The event of the current request, sent again by a retry
  WaitingRoomEvent? _source;

  Stream<WaitingRoomState> _startRequest(
    WaitingRoomEvent source,
    WaitingRoomState waiting,
  ) async* {
    // The server takes an invitation only from a user that is free
    _endRequest(withdraw: true);
    final request = _request;
    _source = source;

    yield waiting;

    unawaited(
      _gameClient.connect().then(
        (_) => _addIfOpen(_Connected(request, source)),
        onError: (Object error) =>
            _addIfOpen(_RequestFailed(request, source, _asException(error))),
      ),
    );
  }

  Stream<WaitingRoomState> _send(int request, WaitingRoomEvent source) async* {
    // Cancelled or replaced while the connection opened
    if (request != _request) return;

    _listen(request, source);
    _requestSent = true;

    try {
      await switch (source) {
        InvitePressed(:final friend) => _gameClient.invite(friend.id),
        ReplyToInvite(:final fromId) => _gameClient.reply(fromId, true),
        _ => _gameClient.find(),
      };
    } catch (error) {
      if (request != _request) return;

      _endRequest();
      yield Failed(_asException(error), retry: source);
    }
  }

  Stream<WaitingRoomState> _onServerSaid(protocol.WaitingEvent message) async* {
    final current = state;

    switch (message) {
      case protocol.Queued():
        yield Queued(_clock());
      case protocol.InviteStatus(status: protocol.InviteStatusKind.sent):
        // The push is out: still waiting for the answer
        break;
      case protocol.InviteStatus(:final status):
        _endRequest();
        yield InviteFinished(
          current is Inviting ? current.target : null,
          status,
        );
      case protocol.ProtocolError(code: protocol.ProtocolError.replaced):
        _endRequest();
        yield Failed(
          const ProtocolErrorException(protocol.ProtocolError.replaced),
          retry: _source,
        );
      case protocol.ProtocolError(code: protocol.ProtocolError.rateLimited)
          when current is Inviting:
        _endRequest();
        yield RateLimited(current.target);
      case protocol.ProtocolError(code: protocol.ProtocolError.invalidState)
          when _source is ReplyToInvite:
        // The accepted invitation will not start a game: nothing else comes
        _endRequest();
        yield const InviteReplyRejected();
      case protocol.ProtocolError(:final code):
        // invalid_state, bad_message: nothing the user can act on
        developer.log('Game server error: $code', name: 'WaitingRoomBloc');
      case protocol.Match():
        // Handled as soon as it arrives, see [_listen]
        break;
    }
  }

  /// Listens to the answers of [request]. The server may still answer an
  /// earlier request that crossed its cancel: only the answers about the
  /// opponent of [source] count.
  void _listen(int request, WaitingRoomEvent source) {
    unawaited(_stopListening());

    final opponentId = switch (source) {
      InvitePressed(:final friend) => friend.id,
      ReplyToInvite(:final fromId) => fromId,
      _ => null,
    };

    _waiting = _gameClient.waiting.listen((message) {
      // A match after close: the cancel that close sent leaves it
      if (_closing || request != _request) return;

      final earlier = switch (message) {
        protocol.Queued() => opponentId != null,
        protocol.InviteStatus(:final userId) => userId != opponentId,
        protocol.Match(:final opponent) =>
          opponentId != null && opponent.id != opponentId,
        protocol.ProtocolError() => false,
      };
      if (earlier) {
        // E.g. a match of the queue that crossed the cancel before an
        // invitation: nobody plays it
        if (message is protocol.Match) _gameClient.leaveMatch();

        return;
      }

      if (message is protocol.Match) {
        // Read at once: the game keeps what the server says from now on
        _requestSent = false;
        _matchPending = true;
        _addIfOpen(_Matched(request, _gameClient.configFor(message)));
      } else {
        _addIfOpen(_ServerSaid(request, message));
      }
    });
    _closes = _gameClient.closes.listen(
      (close) => _addIfOpen(_Closed(request, close)),
    );
  }

  /// Ends the current request; [withdraw] also tells the server, if the
  /// request is on it.
  void _endRequest({bool withdraw = false}) {
    if (withdraw && _requestSent) _withdraw();

    _requestSent = false;
    _request++;
    unawaited(_stopListening());
  }

  void _withdraw() {
    try {
      _gameClient.cancel();
    } on RemoteIOException {
      // Without a connection there is nothing to cancel
    }
  }

  Future<void> _stopListening() async {
    final waiting = _waiting;
    final closes = _closes;
    _waiting = null;
    _closes = null;
    await waiting?.cancel();
    await closes?.cancel();
  }

  static Exception _asException(Object error) =>
      error is Exception ? error : ConnectionException(error.toString());
}
