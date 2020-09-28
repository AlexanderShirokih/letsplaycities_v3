import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/base_list_fetching_screen_mixin.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Battle history list screen
/// Provides a list of user battle history
class OnlineHistoryScreen extends StatefulWidget {
  @override
  _OnlineHistoryScreenState createState() => _OnlineHistoryScreenState();
}

class _OnlineHistoryScreenState extends State<OnlineHistoryScreen>
    with
        BaseListFetchingScreenMixin<HistoryInfo, OnlineHistoryScreen>,
        NetworkAvatarBuildingMixin {
  static final DateFormat _timeFormat = DateFormat('dd.MM.yyyy');

  @override
  Future<List<HistoryInfo>> fetchData(ApiRepository repo, bool forceRefresh) =>
      repo.getHistoryList(forceRefresh);

  @override
  Widget buildItem(
          BuildContext context, ApiRepository repo, HistoryInfo data) =>
      Card(
        elevation: 4.0,
        child: ListTile(
          contentPadding: EdgeInsets.all(8.0),
          leading: buildAvatar(
            data.userId,
            data.login,
            data.pictureUrl,
            46.0,
          ),
          title: Text(data.login),
          subtitle: _buildSubtitle(context, data),
        ),
      );

  Widget _buildSubtitle(BuildContext context, HistoryInfo data) =>
      withLocalization(
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
