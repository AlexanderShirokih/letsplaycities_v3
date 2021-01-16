import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Base class that keeps users data and defines user behaviour.
/// [playerData] is a users data model class
/// [pictureSource] represents users picture
/// [comboSystem] is a system that can calculate score multiplier
/// when user [isTrusted] that means we can omit checking for exclusions and database.
abstract class User {
  final bool isTrusted;
  final ClientAccountInfo accountInfo;
  final ComboSystem comboSystem;

  int _score = 0;

  User({
    required this.accountInfo,
    required this.comboSystem,
    required this.isTrusted,
  });

  /// Current user position
  Position position = Position.UNKNOWN;

  /// Returns true is the user can receive messages
  bool get isMessagesAllowed => accountInfo.canReceiveMessages;

  /// User score points
  int get score => _score;

  /// User name
  String get name => accountInfo.name;

  /// Formatted string representation of score and user name
  String get info => (score == 0) ? name : '$name:$score';

  /// Called by system to increase score points.
  /// [points] is amount of points to be increased.
  void increaseScore(int points) {
    _score = (_score + points * comboSystem.multiplier).floor();
  }

  /// Called by system when users turn begins
  /// [firstChar] is a first letter of that the city should begin.
  /// [firstChar] will be an empty string if it's should be the first word in game.
  /// Returns future with the user's created word
  /// Throws [SurrenderException] is user cannot give answer
  Future<String> onCreateWord(String firstChar);

  /// Closes internal resources
  Future<void> close() => comboSystem.close();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          isTrusted == other.isTrusted &&
          accountInfo == other.accountInfo &&
          _score == other._score &&
          position == other.position;

  @override
  int get hashCode =>
      isTrusted.hashCode ^
      accountInfo.hashCode ^
      _score.hashCode ^
      position.hashCode;
}
