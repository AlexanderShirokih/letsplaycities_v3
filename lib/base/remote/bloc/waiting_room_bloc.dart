import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

part 'waiting_room_event.dart';
part 'waiting_room_state.dart';

/// BLoC used to create game connection
// replaced in protocol v1 task 6: the states still follow the old flow, the
// requests already go over the shared connection of protocol v1.
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState>
    with SequentialEventMapping<WaitingRoomEvent, WaitingRoomState> {
  final RemoteGameClient _gameClient;
  final int _ownerId;

  /// Called when a game starts, so the caller decides which factory is
  /// current at that moment.
  final ApiRepositoryFactory Function() _apiRepositories;

  WaitingRoomBloc(
    this._gameClient,
    this._ownerId, {
    required this._apiRepositories,
  }) : super(WaitingRoomInitial()) {
    mapEventsSequentially(_mapEventToState);
  }

  /// Set as soon as [close] starts: the answers of the server that still
  /// come are dropped.
  bool _closing = false;

  /// Listens to the server while the user waits for a game
  StreamSubscription<Object?>? _waiting;
  StreamSubscription<Object?>? _closes;

  /// Leaves the queue or withdraws the invitation. The connection is shared
  /// and stays open.
  @override
  Future<void> close() async {
    _closing = true;
    await _stopWaiting();
    _cancelRequest();

    return super.close();
  }

  Future<void> _stopWaiting() async {
    final waiting = _waiting;
    final closes = _closes;
    _waiting = null;
    _closes = null;
    await waiting?.cancel();
    await closes?.cancel();
  }

  void _cancelRequest() {
    try {
      _gameClient.cancel();
    } on RemoteIOException {
      // Without a connection there is nothing to cancel
    }
  }

  /// [add] throws StateError once the bloc is closed, so events that come
  /// from network callbacks are dropped while it is closing.
  void _addIfOpen(WaitingRoomEvent event) {
    if (!_closing) add(event);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    if (error is ConnectionException) {
      _addIfOpen(CancelEvent());
      _addIfOpen(OnConnectionFailedEvent());
    } else {
      super.onError(error, stackTrace);
    }
  }

  Stream<WaitingRoomState> _mapEventToState(WaitingRoomEvent event) async* {
    if (event is NewGameRequestEvent) {
      yield* _startConnection(event.request);
    } else if (event is CancelEvent) {
      yield* _stopConnection();
    } else if (event is OnConnectionFailedEvent) {
      yield WaitingRoomConnectionError();
    } else if (event is WaitForOpponentsEvent) {
      yield* _play(event.request);
    } else if (event is StartGameEvent) {
      final apiRepository = _apiRepositories().forUser(_ownerId);

      yield StartGameState(event.config, apiRepository);

      yield WaitingRoomInitial();
    } else if (event is InvitationNegativeResult) {
      yield WaitingRoomInvitationNegativeResult(event.result, event.target);
    }
  }

  Stream<WaitingRoomState> _startConnection(FriendGameRequest? request) async* {
    yield WaitingRoomConnectingState(ConnectionStage.awaitingConnection);
    try {
      await _gameClient.connect();
    } on ApiException catch (e) {
      // The upgrade was refused: unauthorized or banned
      yield WaitingRoomInitial();
      yield WaitingRoomAuthorizationFailed(e.message);
      return;
    } on ProtocolErrorException {
      yield WaitingRoomInitial();
      yield WaitingRoomConnectionError();
      return;
    }
    yield WaitingRoomConnectingState(ConnectionStage.done);

    _addIfOpen(WaitForOpponentsEvent(request));
  }

  Stream<WaitingRoomState> _stopConnection() async* {
    yield WaitingRoomInitial();
    await _stopWaiting();
    _cancelRequest();
  }

  Stream<WaitingRoomState> _play(FriendGameRequest? request) async* {
    final current = state;
    if (current is! WaitingRoomConnectingState ||
        current.connectionStage != ConnectionStage.done) {
      // The connection was cancelled or failed while this event was queued.
      return;
    }

    yield WaitingForOpponentsState(request);

    await _stopWaiting();
    _waiting = _gameClient.waiting.listen(
      (event) => _onWaitingEvent(event, request),
    );
    _closes = _gameClient.closes.listen((_) => _fail());

    final target = request?.target.userId;
    final sent = switch (request?.mode) {
      null => _gameClient.find(),
      FriendGameRequestType.invite => _gameClient.invite(target!),
      FriendGameRequestType.join => _gameClient.reply(target!, true),
    };

    unawaited(
      sent.catchError(
        (_) => _fail(),
        test: (e) => e is ConnectionException || e is RemoteIOException,
      ),
    );
  }

  void _onWaitingEvent(WaitingEvent event, FriendGameRequest? request) {
    switch (event) {
      case Queued():
      case InviteStatus(status: InviteStatusKind.sent):
        break;
      case Match():
        // Read at once: the game keeps what the server says from now on
        final config = _gameClient.configFor(event);
        unawaited(_stopWaiting());
        _addIfOpen(StartGameEvent(config));
      case InviteStatus(:final status):
        unawaited(_stopWaiting());
        _addIfOpen(CancelEvent());
        if (request != null) {
          _addIfOpen(
            InvitationNegativeResult(_inviteResultOf(status), request.target),
          );
        }
      case ProtocolError():
        _fail();
    }
  }

  void _fail() {
    unawaited(_stopWaiting());
    if (state is! WaitingRoomInitial) {
      _addIfOpen(CancelEvent());
      _addIfOpen(OnConnectionFailedEvent());
    }
  }

  static InviteResultType _inviteResultOf(InviteStatusKind status) =>
      switch (status) {
        InviteStatusKind.busy => InviteResultType.busy,
        InviteStatusKind.offline => InviteResultType.noUser,
        InviteStatusKind.notFriends ||
        InviteStatusKind.blocked => InviteResultType.notFriend,
        InviteStatusKind.sent ||
        InviteStatusKind.declined ||
        InviteStatusKind.expired => InviteResultType.denied,
      };
}
