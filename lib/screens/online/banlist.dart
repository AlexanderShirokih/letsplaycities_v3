import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'common_online_widgets.dart';

/// Blocked users list screen
/// Provides a list of users which was blocked by player and the way to remove users from this list
class OnlineBanlistScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<LpsUser> {
  @override
  UserFetchType get fetchEvent => UserFetchType.getBanlist;

  const OnlineBanlistScreen({super.key});

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
    context.t.online.noBlacklistPlaceholder,
    textAlign: TextAlign.center,
    style: withData<TextStyle, TextTheme>(
      Theme.of(context).textTheme,
      (textTheme) =>
          textTheme.headlineSmall!.copyWith(color: textTheme.bodySmall!.color),
    ),
  );

  @override
  Widget buildItem(BuildContext context, LpsUser data) {
    final t = context.t;
    return Card(
      elevation: 4.0,
      child: Dismissible(
        // A reloaded list has to rebuild a row the user swiped away and
        // then restored by Cancel, so the key must not repeat.
        key: UniqueKey(),
        onDismissed: (_) {
          context.read<UserActionsBloc>().add(
            UserEvent(
              data,
              UserUserAction.unbanUser,
              confirmationMessage: t.online.banlistEntryRemoved,
              undoable: true,
            ),
          );
        },
        direction: DismissDirection.endToStart,
        background: _createRemoveFromBanlistBackground(context, t),
        child: _buildListTile(context, data, t),
      ),
    );
  }

  Widget _createRemoveFromBanlistBackground(
    BuildContext context,
    Translations t,
  ) => createPositionedSlideBackground(
    false,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.online.unban,
          style: Theme.of(context).primaryTextTheme.titleSmall,
        ),
        SizedBox(width: 12.0),
        FaIcon(
          FontAwesomeIcons.xmark,
          color: Theme.of(context).primaryIconTheme.color,
        ),
        SizedBox(width: 12.0),
      ],
    ),
  );

  Widget _buildListTile(BuildContext context, LpsUser data, Translations t) =>
      ListTile(
        onTap: () => Navigator.push(
          context,
          OnlineProfileView.createRoute(context, userId: data.id),
        ),
        contentPadding: EdgeInsets.all(8.0),
        leading: lpsUserAvatar(context, data, size: 48),
        title: Text(data.name),
      );
}
