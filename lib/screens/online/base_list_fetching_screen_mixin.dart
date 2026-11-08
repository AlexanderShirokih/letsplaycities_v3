import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_list_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';

import 'common_online_widgets.dart';

/// Provides common functionality for all fetching-type screens.
/// Requires [ApiRepository] to be injected in the widget tree.
mixin BaseListFetchingScreenMixin<T> on StatelessWidget {
  /// Returns appropriate list fetching event type
  UserFetchType get fetchEvent;

  /// Returns target `user` to fetch list from users perspective.
  BaseProfileInfo? get target => null;

  /// Returns widget that will be shown when fetched list is empty
  Widget getOnListEmptyPlaceHolder(BuildContext context);

  /// If `true` ListView will be used as container, otherwise as a Column
  bool get scrollable => true;

  /// Builds item from fetched [data]
  Widget buildItem(BuildContext context, T data);

  /// Creates slider widget which is [Colors.green] for left position
  /// and [Colors.red] for right.
  Widget createPositionedSlideBackground(bool isLeft, Widget child) =>
      Container(
        decoration: BoxDecoration(
          color: isLeft ? Colors.green : Colors.red,
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

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (ctx) =>
            UserListActionsBloc(ctx.read<ApiRepository>(), fetchEvent, target),
      ),
      // Not closed with the screen: the undo snackbar is shown by the
      // app-wide ScaffoldMessenger and may confirm the action after the
      // screen is gone.
      RepositoryProvider(
        create: (ctx) => UserActionsBloc(ctx.read<ApiRepository>()),
      ),
    ],
    // Listens above the list builder, so reloading the list cannot unmount
    // the listener and lose the result of an action.
    child: BlocListener<UserActionsBloc, UserActionsState>(
      listener: _onUserActionState,
      child: BlocBuilder<UserListActionsBloc, UserActionsState>(
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
                  : _showList(context, state.data as List<T>),
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
      // Forced: unbanning a user does not update the cached ban list.
      reloadList(true);
    } else if (state is UserActionErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(context.t.online.actionFailed),
        ),
      );
      // The failed action left the cached list as it was, so reloading from
      // the cache brings back the row the user swiped away.
      reloadList(false);
    }
  }

  Widget _showList(BuildContext context, List<T> data) => scrollable
      ? ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: data.length,
          itemBuilder: (ctx, i) => buildItem(context, data[i]),
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
