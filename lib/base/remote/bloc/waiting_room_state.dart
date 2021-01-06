part of 'waiting_room_bloc.dart';

/// Base state class for [WaitingRoomBloc]
abstract class WaitingRoomState extends Equatable {
  const WaitingRoomState();
}

/// Default state used when no any tasks are running
class WaitingRoomInitial extends WaitingRoomState {
  @override
  List<Object> get props => [];
}

/// Describes connection sequence stages
enum ConnectionStage { awaitingConnection, authorization, done }

/// State that indicates connection process
class WaitingRoomConnectingState extends WaitingRoomState {
  final ConnectionStage connectionStage;

  const WaitingRoomConnectingState(this.connectionStage);

  @override
  List<Object> get props => [connectionStage];
}

/// State used when user waits for available opponents in random pair mode
class WaitingForOpponentsState extends WaitingRoomState {
  @override
  List<Object> get props => [];
}

/// Used when user authorization was failed
class WaitingRoomAuthorizationFailed extends WaitingRoomState {
  final String description;

  const WaitingRoomAuthorizationFailed(this.description);

  @override
  List<Object> get props => [description];
}

/// Used when user authorization was failed
class WaitingRoomConnectionError extends WaitingRoomState {
  const WaitingRoomConnectionError();

  @override
  List<Object> get props => [];
}

/// State used when opponents was found and game should starts
class StartGameState extends WaitingRoomState {
  /// Ready to start network game config
  final GameConfig config;

  const StartGameState(this.config) : assert(config != null);

  @override
  List<Object> get props => [config];
}
