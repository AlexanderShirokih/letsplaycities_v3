import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/data/models/friend_game_request.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:pedantic/pedantic.dart';

part 'waiting_room_event.dart';
part 'waiting_room_state.dart';

/// BLoC used to create game connection
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState> {
  final RemoteGameClient _gameClient;
  final Credential _ownerCredentials;

  WaitingRoomBloc(this._gameClient, this._ownerCredentials)
      : super(WaitingRoomInitial());

  @override
  Future<void> close() {
    return _gameClient.disconnect().whenComplete(() => super.close());
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    if (error is ConnectionException) {
      add(CancelEvent());
      add(OnConnectionFailedEvent());
    } else {
      super.onError(error, stackTrace);
    }
  }

  @override
  Stream<WaitingRoomState> mapEventToState(WaitingRoomEvent event) async* {
    if (event is NewGameRequestEvent) {
      yield* _startConnection(event.request);
    } else if (event is CancelEvent) {
      yield* _stopConnection();
    } else if (event is OnConnectionFailedEvent) {
      yield WaitingRoomConnectionError();
    } else if (event is WaitForOpponentsEvent) {
      yield* _play(event.request);
    } else if (event is StartGameEvent) {
      final apiRepository = GetIt.instance.get<ApiRepository>(
          param1: InstancedCredentialsProvider(_ownerCredentials));

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
    } on UnknownMessageException catch (e) {
      yield* _stopConnection();
      yield WaitingRoomConnectionError();
      return;
    }
    yield WaitingRoomConnectingState(ConnectionStage.done);

    add(WaitForOpponentsEvent(request));
  }

  Stream<WaitingRoomState> _stopConnection() async* {
    yield WaitingRoomInitial();
    await _gameClient.disconnect();
  }

  Stream<WaitingRoomState> _play(FriendGameRequest? request) async* {
    yield WaitingForOpponentsState(request);

    final result =
        request == null ? _gameClient.play() : _gameClient.invite(request);

    unawaited(result.then((result) {
      if (result is GameConfig) {
        add(StartGameEvent(result));
      } else {
        final invResult = result as InvitationResponseMessage;
        add(CancelEvent());
        add(InvitationNegativeResult(invResult.result, request!.target));
      }
    }).catchError((error, stack) {
      if (state is! WaitingRoomInitial) {
        add(CancelEvent());
        add(OnConnectionFailedEvent());
      }
    }, test: (err) => err is ConnectionException));
  }
}
