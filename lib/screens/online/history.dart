import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/i18n/time_format.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/base_list_fetching_screen_mixin.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

/// Battle history list screen
/// Provides a list of user battle history
/// Requires the [ApiRepository] of the signed-in user in the widget tree.
class OnlineHistoryScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<HistoryGame> {
  static final DateFormat _timeFormat = DateFormat('dd.MM.yyyy');

  /// If `true` - column container will used instead of listview
  final bool embedded;

  @override
  bool get scrollable => !embedded;

  @override
  UserFetchType get fetchEvent => UserFetchType.getHistoryList;

  /// Opponents id. If `null` then will showed all account owner history
  @override
  final int? withUser;

  /// Passed to the profiles of the opponents: the invitation of the open
  /// «Онлайн»
  final void Function(LpsUser friend)? onInvite;

  const OnlineHistoryScreen({
    super.key,
    this.withUser,
    this.embedded = false,
    this.onInvite,
  });

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
    context.t.online.noHistoryPlaceholder,
    textAlign: TextAlign.center,
    style: withData<TextStyle, TextTheme>(
      Theme.of(context).textTheme,
      (textTheme) =>
          textTheme.headlineSmall!.copyWith(color: textTheme.bodySmall!.color),
    ),
  );

  @override
  Widget buildItem(BuildContext context, HistoryGame data) => Card(
    elevation: 4.0,
    child: ListTile(
      onTap: () => Navigator.push(
        context,
        OnlineProfileView.createRoute(
          context,
          userId: data.opponent.id,
          onInvite: onInvite,
        ),
      ),
      contentPadding: EdgeInsets.all(8.0),
      leading: Stack(
        alignment: Alignment.bottomRight,
        fit: StackFit.loose,
        children: [
          lpsUserAvatar(context, data.opponent, size: 48),
          if (data.isFriend)
            FaIcon(
              FontAwesomeIcons.userGroup,
              color: Theme.of(context).primaryColor,
            ),
        ],
      ),
      title: Text(data.opponent.name),
      subtitle: Builder(builder: (context) => _buildSubtitle(context, data)),
    ),
  );

  Widget _buildSubtitle(BuildContext context, HistoryGame data) {
    final t = context.t;
    return Align(
      alignment: Alignment.centerLeft,
      child: withData<Widget, Color>(
        Theme.of(context).textTheme.bodySmall!.color!,
        (color) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.calendar, color: color),
                  const SizedBox(width: 8),
                  Text(_timeFormat.format(data.startedAt)),
                  const SizedBox(width: 8),
                  FaIcon(FontAwesomeIcons.stopwatch, color: color),
                  const SizedBox(width: 6),
                  Text(
                    formatMinutesSeconds(t, data.durationSec),
                    overflow: TextOverflow.clip,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.star, color: color),
                const SizedBox(width: 4),
                Text(
                  t.online.wordsCount(count: data.words),
                  overflow: TextOverflow.clip,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
