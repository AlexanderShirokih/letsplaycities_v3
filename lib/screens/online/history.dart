// ignore: import_of_legacy_library_into_null_safe
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/base_list_fetching_screen_mixin.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/screens/online/profile.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Battle history list screen
/// Provides a list of user battle history
/// Requires [ApiRepository] and [AccountManager] repositories in the widget tree.
class OnlineHistoryScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<HistoryInfo>, NetworkAvatarBuildingMixin {
  static final DateFormat _timeFormat = DateFormat('dd.MM.yyyy');

  /// If `true` - column container will used instead of listview
  final bool embedded;

  @override
  bool get scrollable => !embedded;

  @override
  UserFetchType get fetchEvent => UserFetchType.getHistoryList;

  /// Opponents id. If `null` then will showed all account owner history
  @override
  final BaseProfileInfo? target;

  const OnlineHistoryScreen({this.target, this.embedded = false});

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
        buildWithLocalization(
            context, (l10n) => l10n.online['no_history_placeholder']),
        textAlign: TextAlign.center,
        style: withData<TextStyle, TextTheme>(
          Theme.of(context).textTheme,
          (textTheme) =>
              textTheme.headline5!.copyWith(color: textTheme.caption!.color),
        ),
      );

  @override
  Widget buildItem(BuildContext context, HistoryInfo data) => Card(
        elevation: 4.0,
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            OnlineProfileView.createRoute(context, target: data),
          ),
          contentPadding: EdgeInsets.all(8.0),
          leading: Stack(
            alignment: Alignment.bottomRight,
            fit: StackFit.loose,
            children: [
              buildAvatar(data),
              if (data.isFriend)
                FaIcon(
                  FontAwesomeIcons.userFriends,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
          title: Text(data.login),
          subtitle: Builder(
            builder: (context) => _buildSubtitle(context, data),
          ),
        ),
      );

  Widget _buildSubtitle(BuildContext context, HistoryInfo data) =>
      buildWithLocalization(
        context,
        (l10n) => Align(
          alignment: Alignment.centerLeft,
          child: withData<Widget, Color>(
            Theme.of(context).textTheme.caption!.color!,
            (color) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.calendar, color: color),
                      const SizedBox(width: 8),
                      Text(_timeFormat.format(data.startTime)),
                      const SizedBox(width: 8),
                      FaIcon(FontAwesomeIcons.stopwatch, color: color),
                      const SizedBox(width: 6),
                      Text(
                        formatTime(data.duration),
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
                      getPluralForm(
                              (l10n.online['words_count'] as List<dynamic>)
                                  .cast<String>(),
                              data.wordsCount)
                          .format([data.wordsCount]),
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
