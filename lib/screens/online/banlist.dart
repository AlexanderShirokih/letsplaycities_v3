import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'network_avatar_building_mixin.dart';

/// Blocked users list screen
/// Provides a list of users which was blocked by player and the way to remove users from this list
class OnlineBanlistScreen extends StatelessWidget
    with
        BaseListFetchingScreenMixin<BlackListItemInfo>,
        NetworkAvatarBuildingMixin {
  @override
  UserFetchType get fetchEvent => UserFetchType.getBanlist;

  const OnlineBanlistScreen({Key key}) : super(key: key);

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
        buildWithLocalization(
            context, (l10n) => l10n.online['no_blacklist_placeholder']),
        textAlign: TextAlign.center,
        style: withData<TextStyle, TextTheme>(
          Theme.of(context).textTheme,
          (textTheme) =>
              textTheme.headline5.copyWith(color: textTheme.caption.color),
        ),
      );

  @override
  Widget buildItem(
    BuildContext context,
    BlackListItemInfo data,
  ) =>
      readWithLocalization(
        context,
        (l10n) => Card(
          elevation: 4.0,
          child: Dismissible(
            key: ValueKey(data),
            onDismissed: (_) {
              context.read<UserActionsBloc>().add(UserEvent(
                    data,
                    UserUserAction.unbanUser,
                    confirmationMessage: l10n.online['banlist_entry_removed'],
                    undoable: true,
                  ));
            },
            direction: DismissDirection.endToStart,
            background: _createRemoveFromBanlistBackground(context, l10n),
            child: _buildListTile(context, data, l10n),
          ),
        ),
      );

  Widget _createRemoveFromBanlistBackground(
          BuildContext context, LocalizationService l10n) =>
      createPositionedSlideBackground(
        false,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.delete,
              style: Theme.of(context).accentTextTheme.subtitle2,
            ),
            SizedBox(width: 12.0),
            FaIcon(
              FontAwesomeIcons.times,
              color: Theme.of(context).accentIconTheme.color,
            ),
            SizedBox(width: 12.0),
          ],
        ),
      );

  Widget _buildListTile(
    BuildContext context,
    BlackListItemInfo data,
    LocalizationService l10n,
  ) =>
      ListTile(
        onTap: () => Navigator.push(
          context,
          OnlineProfileView.createRoute(context, target: data),
        ),
        contentPadding: EdgeInsets.all(8.0),
        leading: buildAvatar(data),
        title: Text(data.login),
      );
}
