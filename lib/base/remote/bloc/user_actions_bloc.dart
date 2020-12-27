import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:lets_play_cities/remote/auth.dart';

part 'user_actions_event.dart';

part 'user_actions_state.dart';

/// BLoC for managing user actions like friends management
class UserActionsBloc extends Bloc<UserActionsEvent, UserActionsState> {
  final ApiRepository _apiRepository;

  UserActionsBloc(this._apiRepository)
      : assert(_apiRepository != null),
        super(UserActionsInitial());

  @override
  Stream<UserActionsState> mapEventToState(
    UserActionsEvent event,
  ) async* {
    if (event is UserEvent && event.undoable) {
      yield UserActionConfirmationState(event);
      return;
    }

    yield* _doActionsSafely(
      event is UserActionConfirmedEvent ? event.sourceEvent : event,
    );
  }

  Stream<UserActionsState> _doActionsSafely(UserEvent sourceEvent) {
    return _doActions(sourceEvent).transform(
        StreamTransformer<UserActionsState, UserActionsState>.fromHandlers(
      handleError: (e, s, sink) {
        sink.add(
            UserActionDoneState(sourceEvent, e.toString() ?? s.toString()));
      },
    ));
  }

  Stream<UserActionsState> _doActions(UserEvent sourceEvent) async* {
    print('Do action=${sourceEvent.action}');

    final target = sourceEvent.target;
    yield UserProcessingActionState();

    switch (sourceEvent.action) {
      case UserUserAction.addToFriends:
        await _apiRepository.sendNewFriendshipRequest(target);
        break;
      case UserUserAction.removeFromFriends:
      case UserUserAction.cancelRequest:
        await _apiRepository.deleteFriend(target);
        break;
      case UserUserAction.acceptRequest:
        await _apiRepository.sendFriendRequestAcceptance(target, true);
        break;
      case UserUserAction.declineRequest:
        await _apiRepository.sendFriendRequestAcceptance(target, false);
        break;
      case UserUserAction.banUser:
        await _apiRepository.addToBanlist(target);
        break;
      case UserUserAction.unbanUser:
        await _apiRepository.removeFromBanlist(target);
        break;
      case UserUserAction.invite:
        // TODO: Handle this case.
        break;
    }

    yield UserActionDoneState(sourceEvent);
  }
}
