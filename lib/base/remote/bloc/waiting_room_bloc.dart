import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/remote_game_client.dart';
import 'package:pedantic/pedantic.dart';

part 'waiting_room_event.dart';

part 'waiting_room_state.dart';

/// BLoC used to create game connection
class WaitingRoomBloc extends Bloc<WaitingRoomEvent, WaitingRoomState> {
  final RemoteGameClient _gameClient;
  final Credential _ownerCredentials;

  WaitingRoomBloc(this._gameClient, this._ownerCredentials)
      : assert(_gameClient != null),
        assert(_ownerCredentials != null),
        super(WaitingRoomInitial());

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
    if (event is ConnectEvent) {
      yield* _startConnection();
    } else if (event is CancelEvent) {
      yield* _stopConnection();
    } else if (event is OnConnectionFailedEvent) {
      yield WaitingRoomConnectionError();
    } else if (event is PlayEvent) {
      yield* _play(event.opponent);
    } else if (event is StartGameEvent) {
      yield StartGameState(event.players);
    }
  }

  Stream<WaitingRoomState> _startConnection() async* {
    yield WaitingRoomConnectingState(ConnectionStage.awaitingConnection);
    await _gameClient.connect();

    yield WaitingRoomConnectingState(ConnectionStage.authorization);
    try {
      await _gameClient.logIn(_ownerCredentials);
    } on AuthorizationException catch (e) {
      yield* _stopConnection();
      yield WaitingRoomAuthorizationFailed(e.description);
      return;
    }
    yield WaitingRoomConnectingState(ConnectionStage.done);

    add(PlayEvent(null));
  }

  Stream<WaitingRoomState> _stopConnection() async* {
    await _gameClient.disconnect();
    yield WaitingRoomInitial();
  }

  Stream<WaitingRoomState> _play(BaseProfileInfo opponent) async* {
    yield WaitingForOpponentsState();

    unawaited(_gameClient.play(opponent).then((List<Player> players) {
      add(StartGameEvent(players));
    }).catchError((error, stack) {
      print('$error:\n$stack');
      add(CancelEvent());
      add(OnConnectionFailedEvent());
    }));
  }
}
