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

  const UserActionConfirmationState(this.sourceEvent);

  @override
  List<Object> get props => [sourceEvent];
}

class UserProcessingActionState extends UserActionsState {
  @override
  List<Object> get props => [];
}

/// State used to signal en error
class UserActionErrorState extends UserActionsState {
  final Object error;
  final StackTrace stackTrace;

  const UserActionErrorState(this.error, this.stackTrace);

  @override
  List<Object> get props => [error, stackTrace];

  @override
  bool get stringify => true;
}

class UserActionDoneState extends UserActionsState {
  final UserEvent sourceEvent;

  const UserActionDoneState(this.sourceEvent);

  @override
  List<Object> get props => [sourceEvent];
}

class UserActionListDataState<T> extends UserActionsState {
  final List<T> data;

  const UserActionListDataState(this.data);

  @override
  List<Object> get props => [data];
}
