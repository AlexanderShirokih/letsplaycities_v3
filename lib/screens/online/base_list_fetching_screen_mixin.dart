import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_list_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';

import 'common_online_widgets.dart';

/// Provides common functionality for all fetching-type screens.
/// Requires the [ApiRepository] of the signed-in user to be injected in the
/// widget tree.
mixin BaseListFetchingScreenMixin<T> on StatelessWidget {
  /// Returns appropriate list fetching event type
  UserFetchType get fetchEvent;

  /// Id of the user whose games the history shows, `null` for all the games
  /// of the signed-in user.
  int? get withUser => null;

  /// Returns widget that will be shown when fetched list is empty
  Widget getOnListEmptyPlaceHolder(BuildContext context);

  /// If `true` ListView will be used as container, otherwise as a Column
  bool get scrollable => true;

  /// `true` if opening the screen requests the list again instead of using
  /// the cached one, e.g. when the list shows who is online
  bool get refreshOnOpen => false;

  /// Builds item from fetched [data]
  Widget buildItem(BuildContext context, T data);

  /// Builds the fetched, not empty [data]. [hasMore] is `true` while the
  /// server has more pages. By default a list of [buildItem] that asks for
  /// the next page at its end.
  Widget buildBody(
    BuildContext context,
    List<T> data,
    bool hasMore,
    Object? moreError,
  ) => _showList(context, data, hasMore, moreError);

  /// Creates slider widget which is [D2Colors.mint] for left position
  /// and [D2Colors.error] for right.
  Widget createPositionedSlideBackground(
    BuildContext context,
    bool isLeft,
    Widget child,
  ) {
    final c = D2Colors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isLeft ? c.mint : c.error,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (ctx) => UserListActionsBloc(
          ctx.read<ApiRepository>(),
          fetchEvent,
          withUser: withUser,
          refreshOnOpen: refreshOnOpen,
        ),
      ),
      // Not closed with the screen: the undo snackbar is shown by the
      // app-wide ScaffoldMessenger and may confirm the action after the
      // screen is gone.
      RepositoryProvider(
        create: (ctx) => UserActionsBloc(
          ctx.read<ApiRepository>(),
          GetIt.instance.get<AchievementsService>(),
        ),
      ),
    ],
    // Listens above the list builder, so reloading the list cannot unmount
    // the listener and lose the result of an action.
    child: BlocListener<UserActionsBloc, UserActionsState>(
      listener: _onUserActionState,
      child: BlocBuilder<UserListActionsBloc, UserActionsState>(
        // A reload after an action keeps the list on the screen, so what the
        // user typed into it stays.
        buildWhen: (previous, current) =>
            !(previous is UserActionListDataState &&
                current is UserProcessingActionState),
        builder: (context, state) {
          if (state is UserActionListDataState) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<UserListActionsBloc>().add(
                  UserFetchListEvent(true),
                );
              },
              child: state.data.isEmpty
                  ? _showPlaceholder(context)
                  : buildBody(
                      context,
                      state.data as List<T>,
                      state.hasMore,
                      state.moreError,
                    ),
            );
          } else if (state is UserActionErrorState) {
            return showError(context, state.error);
          } else {
            return showLoadingWidget(context);
          }
        },
      ),
    ),
  );

  void _onUserActionState(BuildContext context, UserActionsState state) {
    // The snackbar callbacks run seconds later, when this context may be
    // unmounted, so the blocs are looked up now.
    final actionsBloc = context.read<UserActionsBloc>();
    final listBloc = context.read<UserListActionsBloc>();
    void reloadList(bool forceRefresh) {
      if (!listBloc.isClosed) listBloc.add(UserFetchListEvent(forceRefresh));
    }

    if (state is UserActionConfirmationState) {
      showUndoSnackbar(
        context,
        state.sourceEvent.confirmationMessage!,
        onComplete: () =>
            actionsBloc.add(UserActionConfirmedEvent(state.sourceEvent)),
        onUndo: () {
          actionsBloc.add(const UserActionsResetEvent());
          reloadList(false);
        },
      );
    } else if (state is UserActionDoneState) {
      final message = state.sourceEvent.confirmationMessage;
      // The undo snackbar has already shown the message of an undoable action.
      if (message != null && !state.sourceEvent.undoable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(message),
          ),
        );
      }
      // The repository keeps its cache up to date after an action.
      reloadList(false);
    } else if (state is UserActionErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            state.error is ApiException
                ? errorText(context.t, state.error)
                : context.t.online.actionFailed,
          ),
        ),
      );
      // The failed action left the cached list as it was, so reloading from
      // the cache brings back the row the user swiped away.
      reloadList(false);
    }
  }

  Widget _showList(
    BuildContext context,
    List<T> data,
    bool hasMore,
    Object? moreError,
  ) => scrollable
      ? ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: data.length + (hasMore || moreError != null ? 1 : 0),
          itemBuilder: (ctx, i) => i < data.length
              ? buildItem(context, data[i])
              : moreError != null
              ? _RetryMore(
                  error: moreError,
                  onRetry: () => context.read<UserListActionsBloc>().add(
                    const UserFetchMoreEvent(),
                  ),
                )
              : _LoadMore(
                  onVisible: () => context.read<UserListActionsBloc>().add(
                    const UserFetchMoreEvent(),
                  ),
                ),
        )
      : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: List.generate(
              data.length,
              (i) => buildItem(context, data[i]),
            ),
          ),
        );

  Widget _showPlaceholder(BuildContext context) => Stack(
    children: [
      SizedBox(height: 10.0, child: ListView()),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: getOnListEmptyPlaceHolder(context),
        ),
      ),
    ],
  );
}

/// The end of a paged list: asks for the next page once it is built
class _LoadMore extends StatefulWidget {
  final VoidCallback onVisible;

  const _LoadMore({required this.onVisible});

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  @override
  void initState() {
    super.initState();
    widget.onVisible();
  }

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16.0),
    child: Center(child: CircularProgressIndicator()),
  );
}

/// The end of a paged list whose last page failed: the error and a retry
class _RetryMore extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _RetryMore({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        Text(errorText(context.t, error), textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: Text(context.t.online.reload)),
      ],
    ),
  );
}
