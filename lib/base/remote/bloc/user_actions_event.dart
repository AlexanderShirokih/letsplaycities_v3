part of 'user_actions_bloc.dart';

abstract class UserActionsEvent extends Equatable {
  const UserActionsEvent();
}

enum UserUserAction {
  addToFriends,
  removeFromFriends,
  cancelRequest,
  acceptRequest,
  declineRequest,
  invite,
  banUser,
  unbanUser,
}

class UserEvent extends UserActionsEvent {
  final UserUserAction action;
  final BaseProfileInfo target;
  final String confirmationMessage;
  final bool undoable;

  const UserEvent(this.target, this.action,
      {this.confirmationMessage, this.undoable = false})
      : assert(target != null),
        assert(action != null);

  @override
  List<Object> get props => [target, action, confirmationMessage];
}

class UserActionConfirmedEvent extends UserActionsEvent {
  final UserEvent sourceEvent;

  const UserActionConfirmedEvent(this.sourceEvent)
      : assert(sourceEvent != null);

  @override
  List<Object> get props => [sourceEvent];
}
