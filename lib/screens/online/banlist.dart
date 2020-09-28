import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'network_avatar_building_mixin.dart';

/// Blocked users list screen
/// Provides a list of users which was blocked by player and the way to remove users from this list
class OnlineBanlistScreen extends StatefulWidget {
  const OnlineBanlistScreen({Key key}) : super(key: key);

  @override
  _OnlineBanlistScreenState createState() => _OnlineBanlistScreenState();
}

class _OnlineBanlistScreenState extends State<OnlineBanlistScreen>
    with
        BaseListFetchingScreenMixin<BlackListItemInfo, OnlineBanlistScreen>,
        NetworkAvatarBuildingMixin {
  @override
  Future<List<BlackListItemInfo>> fetchData(
          ApiRepository repo, bool forceRefresh) =>
      repo.getBanlist(forceRefresh);

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
        withLocalization(
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
    ApiRepository repo,
    BlackListItemInfo data,
    int position,
  ) =>
      withLocalization(
        context,
        (l10n) => Card(
          elevation: 4.0,
          child: Dismissible(
            key: ValueKey(data),
            onDismissed: (_) {
              replace(data, null);
              showUndoSnackbar(
                l10n.online['banlist_entry_removed'],
                onComplete: () => repo.removeFromBanlist(data.userId),
                onUndo: () => insert(position, data),
              );
            },
            direction: DismissDirection.endToStart,
            background: _createRemoveFromBanlistBackground(l10n),
            child: _buildListTile(data, l10n),
          ),
        ),
      );

  Widget _createRemoveFromBanlistBackground(LocalizationService l10n) =>
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

  Widget _buildListTile(BlackListItemInfo data, LocalizationService l10n) =>
      ListTile(
        contentPadding: EdgeInsets.all(8.0),
        leading: buildAvatar(
          data.userId,
          data.login,
          data.pictureUrl,
          46.0,
        ),
        title: Text(data.login),
      );
}
