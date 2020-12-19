import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'network_avatar_building_mixin.dart';

/// Friends list screen
/// Provides a list of user friends and the way to remove friends,
/// accept or decline friend requests
class OnlineFriendsScreen extends StatefulWidget {
  const OnlineFriendsScreen({Key key}) : super(key: key);

  @override
  _OnlineFriendsScreenState createState() => _OnlineFriendsScreenState();
}

class _OnlineFriendsScreenState extends State<OnlineFriendsScreen>
    with
        BaseListFetchingScreenMixin<FriendInfo, OnlineFriendsScreen>,
        NetworkAvatarBuildingMixin {
  @override
  Widget buildItem(
    BuildContext context,
    ApiRepository repo,
    FriendInfo data,
    int position,
  ) {
    return readWithLocalization(
      context,
      (l10n) => Card(
        elevation: 4.0,
        child: Dismissible(
          key: ValueKey(data),
          onDismissed: (_) {
            replace(data, null);
            if (data.accepted) {
              showUndoSnackbar(
                l10n.online['removed_from_friends']
                    .toString()
                    .format([data.login]),
                onComplete: () => repo.deleteFriend(data.userId),
                onUndo: () => insert(position, data),
              );
            } else if (data.sender) {
              showUndoSnackbar(
                l10n.online['request_cancelled'],
                onComplete: () => repo.deleteFriend(data.userId),
                onUndo: () => insert(position, data),
              );
            } else {
              showUndoSnackbar(
                l10n.online['request_declined'],
                onComplete: () =>
                    repo.sendFriendRequestAcceptance(data.userId, false),
                onUndo: () => insert(position, data),
              );
            }
          },
          direction: DismissDirection.endToStart,
          background: data.accepted
              ? _createRemoveFromFriendsBackground(l10n)
              : _createDenyFriendsRequestBackground(l10n, data.sender),
          child: _createListTile(data, repo, l10n),
        ),
      ),
    );
  }

  Widget _createRemoveFromFriendsBackground(LocalizationService l10n) =>
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
          LocalizationService l10n, bool canCancel) =>
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
          FriendInfo data, ApiRepository repo, LocalizationService l10n) =>
      ListTile(
        onTap: () => Navigator.push(
          context,
          OnlineProfileView.createRoute(context, targetId: data.userId),
        ),
        contentPadding: EdgeInsets.all(8.0),
        leading: buildAvatar(
          data.userId,
          data.login,
          data.pictureUrl,
          46.0,
        ),
        title: Text(data.login),
        subtitle: data.accepted
            ? null
            : (data.sender
                ? Text(l10n.online['my_request'])
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: FlatButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        repo
                            .sendFriendRequestAcceptance(data.userId, true)
                            .then((_) =>
                                replace(data, data.copy(accepted: true)));
                        showUndoSnackbar(l10n.online['request_accepted']);
                      },
                      child: Text(l10n.online['accept_friendship_request']),
                    ),
                  )),
      );

  @override
  Future<List<FriendInfo>> fetchData(ApiRepository repo, bool forceRefresh) =>
      repo.getFriendsList(forceRefresh);

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
        readWithLocalization(
            context, (l10n) => l10n.online['no_friends_placeholder']),
        textAlign: TextAlign.center,
        style: withData<TextStyle, TextTheme>(
          Theme.of(context).textTheme,
          (textTheme) =>
              textTheme.headline5.copyWith(color: textTheme.caption.color),
        ),
      );
}
