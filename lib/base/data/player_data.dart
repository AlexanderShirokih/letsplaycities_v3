import 'package:lets_play_cities/base/data.dart';

/// Describes player data
class PlayerData {
  /// User name
  final String name;

  /// Profile picture URI
  final PictureSource picture;

  /// `True` is the user wants receive messages from the other users.
  final bool canReceiveMessages;

  const PlayerData({
    this.name,
    this.picture,
    this.canReceiveMessages = false,
  });
}
