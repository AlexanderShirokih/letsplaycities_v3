import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'network_avatar_building_mixin.dart';

/// Friends list screen
/// Provides a list of user friends and the way to remove friends,
/// accept or decline friend requests
class OnlineFriendsScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<FriendInfo>, NetworkAvatarBuildingMixin {
  const OnlineFriendsScreen({super.key});

  @override
  UserFetchType get fetchEvent => UserFetchType.getFriendsList;

  @override
  Widget buildItem(BuildContext context, FriendInfo data) {
    final t = context.t;
    return Card(
      elevation: 4.0,
      child: Dismissible(
        key: UniqueKey(),
        onDismissed: (_) {
          if (data.accepted) {
            context.read<UserActionsBloc>().add(
              UserEvent(
                data,
                UserUserAction.removeFromFriends,
                confirmationMessage: t.online.removedFromFriends(
                  login: data.login,
                ),
                undoable: true,
              ),
            );
          } else if (data.sender) {
            context.read<UserActionsBloc>().add(
              UserEvent(
                data,
                UserUserAction.removeFromFriends,
                confirmationMessage: t.online.requestCancelled,
              ),
            );
          } else {
            context.read<UserActionsBloc>().add(
              UserEvent(
                data,
                UserUserAction.declineRequest,
                confirmationMessage: t.online.requestDeclined,
              ),
            );
          }
        },
        direction: DismissDirection.endToStart,
        background: data.accepted
            ? _createRemoveFromFriendsBackground(context, t)
            : _createDenyFriendsRequestBackground(context, t, data.sender),
        child: _createListTile(context, data, t),
      ),
    );
  }

  Widget _createRemoveFromFriendsBackground(
    BuildContext context,
    Translations t,
  ) => createPositionedSlideBackground(
    false,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.online.removeFromFriends,
          style: Theme.of(context).primaryTextTheme.titleSmall,
        ),
        SizedBox(width: 12.0),
        FaIcon(
          FontAwesomeIcons.userMinus,
          color: Theme.of(context).primaryIconTheme.color,
        ),
        SizedBox(width: 12.0),
      ],
    ),
  );

  Widget _createDenyFriendsRequestBackground(
    BuildContext context,
    Translations t,
    bool canCancel,
  ) => createPositionedSlideBackground(
    false,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          canCancel
              ? t.online.cancelFriendshipRequest
              : t.online.declineFriendshipRequest,
          style: Theme.of(context).primaryTextTheme.titleSmall,
        ),
        SizedBox(width: 12.0),
        FaIcon(
          canCancel ? FontAwesomeIcons.xmark : FontAwesomeIcons.userXmark,
          color: Theme.of(context).primaryIconTheme.color,
        ),
        SizedBox(width: 12.0),
      ],
    ),
  );

  Widget _createListTile(
    BuildContext context,
    FriendInfo data,
    Translations t,
  ) => ListTile(
    onTap: () => Navigator.push(
      context,
      OnlineProfileView.createRoute(context, target: data),
    ),
    contentPadding: EdgeInsets.all(8.0),
    leading: buildAvatar(data),
    title: Text(data.login),
    subtitle: data.accepted
        ? null
        : (data.sender
              ? Text(t.online.myRequest)
              : Align(
                  alignment: Alignment.bottomLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => context.read<UserActionsBloc>().add(
                      UserEvent(
                        data,
                        UserUserAction.acceptRequest,
                        confirmationMessage: t.online.requestAccepted,
                      ),
                    ),
                    child: Text(t.online.acceptFriendshipRequest),
                  ),
                )),
  );

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
    context.t.online.noFriendsPlaceholder,
    textAlign: TextAlign.center,
    style: withData<TextStyle, TextTheme>(
      Theme.of(context).textTheme,
      (textTheme) =>
          textTheme.headlineSmall!.copyWith(color: textTheme.bodySmall!.color),
    ),
  );
}
