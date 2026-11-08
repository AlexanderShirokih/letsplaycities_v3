import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@sealed
class IncomingCloudMessage {
  const IncomingCloudMessage();
}

/// Invitation to a game, the push `{type: "invite", fromId, fromName}`.
/// The push does not say who it is for: the account that is signed in
/// answers it.
class GameRequest extends IncomingCloudMessage with Equatable {
  /// The `type` of the push data
  static const pushType = 'invite';

  /// ID of the user who invites
  final int fromId;

  /// Name of the user who invites
  final String fromName;

  const GameRequest(this.fromId, this.fromName);

  /// Reads [data] of a push; `null` unless it is a well-formed invitation.
  /// FCM delivers every value as a string.
  static GameRequest? tryParse(Map<String, dynamic> data) {
    if (data['type'] != pushType) return null;

    final fromId = int.tryParse('${data['fromId']}');
    final fromName = data['fromName'];
    if (fromId == null || fromName is! String) return null;

    return GameRequest(fromId, fromName);
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [fromId, fromName];
}
