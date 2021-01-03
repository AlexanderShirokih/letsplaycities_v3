import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'network_avatar_building_mixin.dart';

/// Friends list screen
/// Provides a list of user friends and the way to remove friends,
/// accept or decline friend requests
class OnlineFriendsScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<FriendInfo>, NetworkAvatarBuildingMixin {
  const OnlineFriendsScreen({Key key}) : super(key: key);

  @override
  UserFetchType get fetchEvent => UserFetchType.getFriendsList;

  @override
  Widget buildItem(BuildContext context, FriendInfo data) {
    return readWithLocalization(
      context,
      (l10n) => Card(
        elevation: 4.0,
        child: Dismissible(
          key: UniqueKey(),
          onDismissed: (_) {
            if (data.accepted) {
              context.read<UserActionsBloc>().add(UserEvent(
                    data,
                    UserUserAction.removeFromFriends,
                    confirmationMessage: l10n.online['removed_from_friends']
                        .toString()
                        .format([data.login]),
                    undoable: true,
                  ));
            } else if (data.sender) {
              context.read<UserActionsBloc>().add(UserEvent(
                  data, UserUserAction.removeFromFriends,
                  confirmationMessage: l10n.online['request_cancelled']));
            } else {
              context.read<UserActionsBloc>().add(UserEvent(
                  data, UserUserAction.declineRequest,
                  confirmationMessage: l10n.online['request_declined']));
            }
          },
          direction: DismissDirection.endToStart,
          background: data.accepted
              ? _createRemoveFromFriendsBackground(context, l10n)
              : _createDenyFriendsRequestBackground(context, l10n, data.sender),
          child: _createListTile(context, data, l10n),
        ),
      ),
    );
  }

  Widget _createRemoveFromFriendsBackground(
          BuildContext context, LocalizationService l10n) =>
      createPositionedSlideBackground(
        false,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.online['remove_from_friends'],
                style: Theme.of(context).accentTextTheme.subtitle2),
            SizedBox(width: 12.0),
            FaIcon(
              FontAwesomeIcons.userMinus,
              color: Theme.of(context).accentIconTheme.color,
            ),
            SizedBox(width: 12.0),
          ],
        ),
      );

  Widget _createDenyFriendsRequestBackground(
          BuildContext context, LocalizationService l10n, bool canCancel) =>
      createPositionedSlideBackground(
        false,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                l10n.online[canCancel
                    ? 'cancel_friendship_request'
                    : 'decline_friendship_request'],
                style: Theme.of(context).accentTextTheme.subtitle2),
            SizedBox(width: 12.0),
            FaIcon(
              canCancel ? FontAwesomeIcons.times : FontAwesomeIcons.userTimes,
              color: Theme.of(context).accentIconTheme.color,
            ),
            SizedBox(width: 12.0),
          ],
        ),
      );

  Widget _createListTile(
          BuildContext context, FriendInfo data, LocalizationService l10n) =>
      ListTile(
        onTap: () => Navigator.push(
          context,
          OnlineProfileView.createRoute(context, target: data),
        ),
        contentPadding: EdgeInsets.all(8.0),
        leading: buildAvatar(data, 46.0),
        title: Text(data.login),
        subtitle: data.accepted
            ? null
            : (data.sender
                ? Text(l10n.online['my_request'])
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: FlatButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.watch<UserActionsBloc>().add(
                          UserEvent(data, UserUserAction.acceptRequest,
                              confirmationMessage:
                                  l10n.online['request_accepted'])),
                      child: Text(l10n.online['accept_friendship_request']),
                    ),
                  )),
      );

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
        buildWithLocalization(
            context, (l10n) => l10n.online['no_friends_placeholder']),
        textAlign: TextAlign.center,
        style: withData<TextStyle, TextTheme>(
          Theme.of(context).textTheme,
          (textTheme) =>
              textTheme.headline5.copyWith(color: textTheme.caption.color),
        ),
      );
}
