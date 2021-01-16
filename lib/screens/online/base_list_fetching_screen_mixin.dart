import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_list_actions_bloc.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

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
  Widget build(BuildContext context) => Container(
        child: withData<Widget, ApiRepository>(
          context.watch<ApiRepository>(),
          (apiRepo) => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: UserListActionsBloc(apiRepo, fetchEvent, target),
              ),
              BlocProvider.value(
                value: UserActionsBloc(apiRepo),
              ),
            ],
            child: BlocBuilder<UserListActionsBloc, UserActionsState>(
              builder: (context, state) {
                if (state is UserActionListDataState) {
                  return BlocListener<UserActionsBloc, UserActionsState>(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<UserListActionsBloc>()
                              .add(UserFetchListEvent(true));
                        },
                        child: state.data.isEmpty
                            ? _showPlaceholder(context)
                            : _showList(context, state.data as List<T>),
                      ),
                      listener: (context, state) {
                        if (state is UserActionConfirmationState) {
                          showUndoSnackbar(
                            context,
                            state.sourceEvent.confirmationMessage!,
                            onComplete: () => context
                                .read<UserActionsBloc>()
                                .add(state.sourceEvent),
                            onUndo: () => context
                                .read<UserListActionsBloc>()
                                .add(UserFetchListEvent(false)),
                          );
                        } else if (state is UserActionDoneState) {
                          final message = state.sourceEvent.confirmationMessage;
                          if (message != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 3),
                                content: Text(message),
                              ),
                            );
                          }
                        }
                      });
                } else if (state is UserActionErrorState) {
                  return showError(context, state.error);
                } else {
                  return showLoadingWidget(context);
                }
              },
            ),
          ),
        ),
      );

  Widget _showList(BuildContext context, List<T> data) => scrollable
      ? ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: data.length,
          itemBuilder: (ctx, i) => buildItem(context, data[i]),
        )
      : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children:
                List.generate(data.length, (i) => buildItem(context, data[i])),
          ),
        );

  Widget _showPlaceholder(BuildContext context) => Stack(
        children: [
          Container(height: 10.0, child: ListView()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: getOnListEmptyPlaceHolder(context),
            ),
          )
        ],
      );
}
