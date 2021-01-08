import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

/// BLoC for managing user actions like friends management
class UserListActionsBloc extends Bloc<UserActionsEvent, UserActionsState> {
  final ApiRepository _apiRepository;
  final UserFetchType fetchType;
  final BaseProfileInfo target;

  UserListActionsBloc(this._apiRepository, this.fetchType, [this.target])
      : assert(_apiRepository != null),
        assert(fetchType != null),
        super(UserActionsInitial()) {
    add(UserFetchListEvent(false));
  }

  @override
  Stream<UserActionsState> mapEventToState(UserActionsEvent event) async* {
    if (event is UserFetchListEvent) {
      yield* _handleFetchEventSafely(event);
    }
  }

  Stream<UserActionsState> _handleFetchEventSafely(UserFetchListEvent event) {
    return _handleFetchEvent(event).transform(
        StreamTransformer<UserActionsState, UserActionsState>.fromHandlers(
      handleError: (e, s, sink) {
        sink.add(UserActionErrorState(e.toString(), s));
      },
    ));
  }

  Stream<UserActionsState> _handleFetchEvent(UserFetchListEvent event) async* {
    yield UserProcessingActionState();

    Future<List> data;

    switch (fetchType) {
      case UserFetchType.getFriendsList:
        data = _apiRepository.getFriendsList(event.forceRefresh);
        break;
      case UserFetchType.getHistoryList:
        data = _apiRepository.getHistoryList(event.forceRefresh, target);
        break;
      case UserFetchType.getBanlist:
        data = _apiRepository.getBanlist(event.forceRefresh);
        break;
      default:
        throw ('Unknown fetch type! $fetchType');
    }

    yield UserActionListDataState(await data);
  }
}
