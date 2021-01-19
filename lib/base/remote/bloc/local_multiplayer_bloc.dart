import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/platform/network_manager.dart';

part 'local_multiplayer_event.dart';

part 'local_multiplayer_state.dart';

/// Bloc for handling local multiplayer connections
class LocalMultiplayerBloc
    extends Bloc<LocalMultiplayerEvent, LocalMultiplayerState> {
  LocalMultiplayerBloc() : super(LocalMultiplayerInitial());

  @override
  Stream<LocalMultiplayerState> mapEventToState(
      LocalMultiplayerEvent event) async* {
    if (event is LocalMultiplayerCreate) {
      yield* _createConnection();
    } else if (event is LocalMultiplayerConnect) {
      yield* _connectToServer();
    }
  }

  Stream<LocalMultiplayerState> _createConnection() async* {
    final isNetworkReady = await NetworkManager.unsureHotspotEnabled();

    if (isNetworkReady) {
      yield LocalMultiplayerWaitingForConnections();
    }
  }

  Stream<LocalMultiplayerState> _connectToServer() async* {
    final isNetworkReady = await NetworkManager.unsureWifiConnected();

    if (isNetworkReady) {
      yield LocalMultiplayerJoiningState();
    } else {
      yield LocalMultiplayerNoWifiState();
      yield LocalMultiplayerInitial();
    }
  }
}
