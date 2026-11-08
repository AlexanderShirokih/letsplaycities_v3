part of 'game_request_bloc.dart';

/// Base event for [GameRequestBloc]
abstract class GameRequestEvent extends Equatable {
  const GameRequestEvent();
}

/// Emits new request
class InputGameRequestEvent extends GameRequestEvent {
  final GameRequest request;

  const InputGameRequestEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Used to send request result
class GameRequestResultEvent extends GameRequestEvent {
  final RequestResult result;

  const GameRequestResultEvent(this.result);

  @override
  List<Object?> get props => [result];
}
