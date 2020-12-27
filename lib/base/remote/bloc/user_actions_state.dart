part of 'user_actions_bloc.dart';

abstract class UserActionsState extends Equatable {
  const UserActionsState();
}

class UserActionsInitial extends UserActionsState {
  @override
  List<Object> get props => [];
}

class UserActionConfirmationState extends UserActionsState {
  final UserEvent sourceEvent;

  const UserActionConfirmationState(this.sourceEvent)
      : assert(sourceEvent != null);

  @override
  List<Object> get props => [sourceEvent];
}

class UserProcessingActionState extends UserActionsState {
  @override
  List<Object> get props => [];
}

class UserActionDoneState extends UserActionsState {
  final String error;
  final UserEvent sourceEvent;

  const UserActionDoneState(this.sourceEvent, [this.error]);

  @override
  List<Object> get props => [sourceEvent, error];
}
