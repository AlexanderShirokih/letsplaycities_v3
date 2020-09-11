import 'package:lets_play_cities/base/game/scoring/scoring_type.dart';

/// Represents application preferences
class GamePreferences {
  /// Words difficulty level.
  /// Where: 0- easy, 1-medium, 2-hard.
  int get wordsDifficulty => 0;

  /// `true` when words spelling correction is enabled.
  bool get correctionEnabled => false;

  /// Time limit per users move in local game modes.
  /// `0` means timer is disabled.
  int get timeLimit => 92;

  /// Defines game score calculation and winner checking strategy.
  ScoringType get scoringType => ScoringType.BY_SCORE;

  /// Returns string containing JSON-encoded representation of score data.
  String get scoringData => "";

  /// Returns string containing legacy representation of score data.
  String get legacyScoringData => "";

  /// Returns last dictionary updates checking date.
  DateTime get lastDictionaryCheckDate => DateTime.now();

  /// Gets dictionary update checking interval in hours.
  int get dictionaryUpdatePeriod => 1;
}
