import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:meta/meta.dart';

@sealed
class IncomingCloudMessage {
  const IncomingCloudMessage();
}

/// Describes game request results
enum RequestResult { accepted, declined }

/// Game request model received from remote service.
class GameRequest extends IncomingCloudMessage with EquatableMixin {
  /// Request sender login
  final String login;

  /// Request sender ID
  final int userId;

  /// Request receiver target
  final int targetId;

  const GameRequest(this.login, this.userId, this.targetId);

  @override
  bool get stringify => true;

  /// Creates [GameRequest] instance from [Map]
  factory GameRequest.fromMap(Map<String, dynamic> data) => GameRequest(
        data['login'],
        int.parse(data['user_id']),
        int.parse(data['target_id']),
      );

  /// Returns [BaseProfileInfo] containing requester login and ID
  BaseProfileInfo get requester => BaseProfileInfo(
        userId: userId,
        login: login,
      );

  @override
  List<Object?> get props => [login, userId, targetId];
}
