import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lets_play_cities/remote/account_manager.dart';

import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/base_list_fetching_screen_mixin.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/screens/online/profile.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Battle history list screen
/// Provides a list of user battle history
/// Requires [ApiRepository] and [AccountManager] repositories in the widget tree.
class OnlineHistoryScreen extends StatefulWidget {
  /// Opponents id. If `null` then will showed all account owner history
  final int targetId;

  /// If `true` - column container will used instead of listview
  final bool embedded;

  const OnlineHistoryScreen({this.targetId, this.embedded = false});

  @override
  _OnlineHistoryScreenState createState() => _OnlineHistoryScreenState();
}

class _OnlineHistoryScreenState extends State<OnlineHistoryScreen>
    with
        BaseListFetchingScreenMixin<HistoryInfo, OnlineHistoryScreen>,
        NetworkAvatarBuildingMixin {
  static final DateFormat _timeFormat = DateFormat('dd.MM.yyyy');

  @override
  bool get scrollable => !widget.embedded;

  @override
  Future<List<HistoryInfo>> fetchData(
      ApiRepository repo, bool forceRefresh) async {
    final account =
        await context.read<AccountManager>().getLastSignedInAccount();
    return repo.getHistoryList(forceRefresh, targetId: _getTargetId(account));
  }

  int _getTargetId(RemoteAccountInfo account) =>
      widget.targetId != null && account.credential.userId != widget.targetId
          ? widget.targetId
          : null;

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
        buildWithLocalization(
            context, (l10n) => l10n.online['no_history_placeholder']),
        textAlign: TextAlign.center,
        style: withData<TextStyle, TextTheme>(
          Theme.of(context).textTheme,
          (textTheme) =>
              textTheme.headline5.copyWith(color: textTheme.caption.color),
        ),
      );

  @override
  Widget buildItem(
          BuildContext context, ApiRepository repo, HistoryInfo data, _) =>
      Card(
        elevation: 4.0,
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            OnlineProfileView.createRoute(context, targetId: data.userId),
          ),
          contentPadding: EdgeInsets.all(8.0),
          leading: Stack(
            alignment: Alignment.bottomRight,
            fit: StackFit.loose,
            children: [
              buildAvatar(
                data.userId,
                data.login,
                data.pictureUrl,
                46.0,
              ),
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
            Theme.of(context).textTheme.caption.color,
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
