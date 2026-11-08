import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/social.dart';

/// BLoC that fetches the lists of the social screens: the friends, the
/// history and the blocked users. The history comes in pages.
class UserListActionsBloc extends Bloc<UserActionsEvent, UserActionsState>
    with SequentialEventMapping<UserActionsEvent, UserActionsState> {
  final ApiRepository _apiRepository;
  final UserFetchType fetchType;

  /// Only for the history: the games with this user, with everybody if `null`
  final int? withUser;

  /// `true` if the first request skips the cache: the online status of the
  /// users in the cached lists is old
  final bool refreshOnOpen;

  final _games = <HistoryGame>[];
  int? _next;

  UserListActionsBloc(
    this._apiRepository,
    this.fetchType, {
    this.withUser,
    this.refreshOnOpen = false,
  }) : super(UserActionsInitial()) {
    mapEventsSequentially(_mapEventToState);
    add(UserFetchListEvent(refreshOnOpen));
  }

  Stream<UserActionsState> _mapEventToState(UserActionsEvent event) async* {
    if (event is UserFetchListEvent) {
      yield* _safely(_fetch(event.forceRefresh));
    } else if (event is UserFetchMoreEvent) {
      yield* _fetchMore();
    }
  }

  Stream<UserActionsState> _safely(Stream<UserActionsState> states) {
    return states.transform(
      StreamTransformer<UserActionsState, UserActionsState>.fromHandlers(
        handleError: (e, s, sink) {
          // The error itself, not its text: the screen words some errors
          // for the player.
          sink.add(UserActionErrorState(e, s));
        },
      ),
    );
  }

  Stream<UserActionsState> _fetch(bool forceRefresh) async* {
    yield UserProcessingActionState();

    switch (fetchType) {
      case UserFetchType.getFriendsList:
        yield UserActionListDataState(
          await _apiRepository.friends(forceRefresh),
        );
        break;
      case UserFetchType.getHistoryList:
        final page = await _apiRepository.history(
          withUser: withUser,
          forceRefresh: forceRefresh,
        );
        _games
          ..clear()
          ..addAll(page.games);
        _next = page.next;
        yield _historyState();
        break;
      case UserFetchType.getBanlist:
        yield UserActionListDataState(
          await _apiRepository.blocks(forceRefresh),
        );
        break;
    }
  }

  /// A failed page keeps the pages that are loaded and offers a retry
  Stream<UserActionsState> _fetchMore() async* {
    final cursor = _next;
    if (fetchType != UserFetchType.getHistoryList || cursor == null) return;

    try {
      final page = await _apiRepository.history(
        withUser: withUser,
        before: cursor,
      );
      _games.addAll(page.games);
      _next = page.next;
      yield _historyState();
    } catch (e) {
      yield _historyState(moreError: e);
    }
  }

  UserActionListDataState<HistoryGame> _historyState({Object? moreError}) =>
      UserActionListDataState(
        List.of(_games),
        hasMore: _next != null,
        moreError: moreError,
      );
}
