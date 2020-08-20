import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/management.dart';

/// Base class that keeps users data and defines user behaviour.
/// [playerData] is a users data model class
/// [pictureSource] represents users picture
abstract class User {
  final PlayerData playerData;
  final PictureSource pictureSource;

  int _score = 0;

  User(this.playerData, PictureSource pictureSource)
      : this.pictureSource = pictureSource ?? PlaceholderPictureSource();

  /// Current user position
  Position position = Position.UNKNOWN;

  /// Returns true is the user can receive messages
  bool get isMessagesAllowed => playerData.canReceiveMessages;

  /// User score points
  int get score => _score;

  /// User name
  String get name => playerData.accountInfo.name;

  /// Formatted string representation of score and user name
  String get info => (score == 0) ? name : "$name:$score";

  /// Called by system to increase score points.
  /// [points] is amount of points to be increased.
  /// TODO: [points] will be multiplied by current combo multiplier.
  increaseScore(int points) {
    _score += points; //points * comboSystem.multiplier
  }

  /// Called by system when users turn begins
  /// [firstChar] is a first letter of that the city should begin.
  /// Will be an empty string if it's should be the first word in game.
  /// Returns Stream with word response [ResultWithCity]. To finish move, [User]
  /// should complete the stream.
  Stream<ResultWithCity> onMakeMove(String firstChar) async* {}
}
