import 'package:lets_play_cities/remote/auth.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/remote/model/utils.dart';

/// A data class describing battle history record
class HistoryInfo extends BaseProfileInfo {
  /// `true` if this user is a friend to request owner
  final bool isFriend;

  /// Entity creation data (timestamp)
  final DateTime startTime;

  /// Battle duration in seconds
  final int duration;

  /// Count of words used in game by both users
  final int wordsCount;

  const HistoryInfo._({
    @required int userId,
    @required String login,
    @required String pictureUrl,
    @required this.isFriend,
    @required this.startTime,
    @required this.duration,
    @required this.wordsCount,
  })  : assert(isFriend != null),
        assert(duration != null),
        assert(wordsCount != null),
        assert(startTime != null),
        super(userId: userId, login: login, pictureUrl: pictureUrl);

  HistoryInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          isFriend: data['isFriend'] == 'true',
          duration: data['duration'],
          wordsCount: data['wordsCount'],
          startTime: DateTime.fromMillisecondsSinceEpoch(data['startTime']),
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
        );

  @override
  List<Object> get props => [
        ...super.props,
        isFriend,
        duration,
        wordsCount,
        startTime,
      ];
}
