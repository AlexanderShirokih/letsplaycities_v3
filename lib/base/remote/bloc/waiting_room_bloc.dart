import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

part 'waiting_room_event.dart';
part 'waiting_room_state.dart';

/// BLoC used to create game connection
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState>
    with SequentialEventMapping<WaitingRoomEvent, WaitingRoomState> {
  final RemoteGameClient _gameClient;
  final Credential _ownerCredentials;

  /// Called when a game starts, so the caller decides which factory is
  /// current at that moment.
  final ApiRepositoryFactory Function() _apiRepositories;

  WaitingRoomBloc(
    this._gameClient,
    this._ownerCredentials, {
    required this._apiRepositories,
  }) : super(WaitingRoomInitial()) {
    mapEventsSequentially(_mapEventToState);
  }

  /// Set as soon as [close] starts. [isClosed] stays false while [close]
  /// waits for the disconnect, and that disconnect is what fails a pending
  /// [RemoteGameClient.play] or [RemoteGameClient.invite].
  bool _closing = false;

  @override
  Future<void> close() {
    _closing = true;
    return _gameClient.disconnect().whenComplete(() => super.close());
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
      final apiRepository = _apiRepositories().forCredential(_ownerCredentials);

      yield StartGameState(event.config, apiRepository);

      yield WaitingRoomInitial();
    } else if (event is InvitationNegativeResult) {
      yield WaitingRoomInvitationNegativeResult(event.result, event.target);
    }
  }

  Stream<WaitingRoomState> _startConnection(FriendGameRequest? request) async* {
    yield WaitingRoomConnectingState(ConnectionStage.awaitingConnection);
    await _gameClient.connect();

    yield WaitingRoomConnectingState(ConnectionStage.authorization);
    try {
      await _gameClient.logIn(_ownerCredentials);
    } on AuthorizationException catch (e) {
      yield* _stopConnection();
      yield WaitingRoomAuthorizationFailed(e.description);
      return;
    } on UnknownMessageException {
      yield* _stopConnection();
      yield WaitingRoomConnectionError();
      return;
    }
    yield WaitingRoomConnectingState(ConnectionStage.done);

    _addIfOpen(WaitForOpponentsEvent(request));
  }

  Stream<WaitingRoomState> _stopConnection() async* {
    yield WaitingRoomInitial();
    await _gameClient.disconnect();
  }

  Stream<WaitingRoomState> _play(FriendGameRequest? request) async* {
    final current = state;
    if (current is! WaitingRoomConnectingState ||
        current.connectionStage != ConnectionStage.done) {
      // The connection was cancelled or failed while this event was queued.
      return;
    }

    yield WaitingForOpponentsState(request);

    final result = request == null
        ? _gameClient.play()
        : _gameClient.invite(request);

    unawaited(
      result
          .then((result) {
            if (result is GameConfig) {
              _addIfOpen(StartGameEvent(result));
            } else {
              final invResult = result as InvitationResponseMessage;
              _addIfOpen(CancelEvent());
              _addIfOpen(
                InvitationNegativeResult(invResult.result, request!.target),
              );
            }
          })
          .catchError((error, stack) {
            if (state is! WaitingRoomInitial) {
              _addIfOpen(CancelEvent());
              _addIfOpen(OnConnectionFailedEvent());
            }
          }, test: (err) => err is ConnectionException),
    );
  }
}
