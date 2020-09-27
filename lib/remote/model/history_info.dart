import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/remote/model/utils.dart';

/// A data class describing battle history record
class HistoryInfo extends Equatable {
  /// Opponent user id
  final int userId;

  /// Opponent user name
  final String login;

  /// Opponent user picture URL
  final String pictureUrl;

  /// `true` if this user is a friend to request owner
  final bool isFriend;

  /// Entity creation data (timestamp)
  final String creationDate;

  /// Battle duration in seconds
  final int duration;

  /// Count of words used in game by both users
  final int wordsCount;

  const HistoryInfo._({
    @required this.userId,
    @required this.login,
    @required this.isFriend,
    @required this.creationDate,
    @required this.duration,
    @required this.wordsCount,
    @required this.pictureUrl,
  })  : assert(login != null),
        assert(userId != null),
        assert(isFriend != null),
        assert(duration != null),
        assert(wordsCount != null),
        assert(creationDate != null);

  HistoryInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          isFriend: data['isFriend'] == 'true',
          duration: data['duration'],
          wordsCount: data['wordsCount'],
          creationDate: data['creationDate'],
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
        );

  @override
  List<Object> get props => [
        userId,
        login,
        pictureUrl,
        isFriend,
        duration,
        wordsCount,
        creationDate,
      ];
}
