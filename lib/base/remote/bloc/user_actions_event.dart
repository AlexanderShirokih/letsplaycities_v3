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
  banUser,
  unbanUser,
}

enum UserFetchType {
  getFriendsList,
  getHistoryList,
  getBanlist,
}

class UserFetchListEvent extends UserActionsEvent {
  final bool forceRefresh;

  UserFetchListEvent(this.forceRefresh);

  @override
  List<Object> get props => [forceRefresh];
}

class UserEvent extends UserActionsEvent {
  final UserUserAction action;
  final BaseProfileInfo target;
  final String? confirmationMessage;
  final bool undoable;

  const UserEvent(this.target, this.action,
      {this.confirmationMessage, this.undoable = false});

  @override
  List<Object> get props => [target, action, confirmationMessage ?? ''];
}

class UserActionConfirmedEvent extends UserActionsEvent {
  final UserEvent sourceEvent;

  const UserActionConfirmedEvent(this.sourceEvent);

  @override
  List<Object> get props => [sourceEvent];
}
