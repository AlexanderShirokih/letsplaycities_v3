import 'package:lets_play_cities/base/auth.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';

/// Base class that keeps users data and defines user behaviour.
/// [playerData] is a users data model class
/// [pictureSource] represents users picture
/// when user [isTrusted] that means we can omit checking for exclusions and database.
abstract class User {
  final bool isTrusted;
  final PlayerData playerData;
  final ClientAccountInfo accountInfo;

  int _score = 0;

  User({this.playerData, this.accountInfo, this.isTrusted})
      : assert(playerData != null),
        assert(accountInfo != null),
        assert(isTrusted != null);

  /// Current user position
  Position position = Position.UNKNOWN;

  /// Returns true is the user can receive messages
  bool get isMessagesAllowed => playerData.canReceiveMessages;

  /// User score points
  int get score => _score;

  /// User name
  String get name => playerData.name;

  /// Formatted string representation of score and user name
  String get info => (score == 0) ? name : "$name:$score";

  /// Returns user ID or -1 if this user don't have account info
  int get id => accountInfo?.credential?.userId ?? -1;

  /// Called by system to increase score points.
  /// [points] is amount of points to be increased.
  /// TODO: [points] will be multiplied by current combo multiplier.
  increaseScore(int points) {
    _score += points; //points * comboSystem.multiplier
  }

  /// Called by system when users turn begins
  /// [firstChar] is a first letter of that the city should begin.
  /// [firstChar] will be an empty string if it's should be the first word in game.
  /// Returns future with the user's created word
  /// Throws [SurrenderException] is user cannot give answer
  Future<String> onCreateWord(String firstChar);
}
