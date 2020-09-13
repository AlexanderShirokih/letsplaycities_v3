import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/scoring/scoring_type.dart';

/// Represents application preferences
abstract class GamePreferences {
  /// Words difficulty level.
  Difficulty wordsDifficulty;

  /// `true` when words spelling correction is enabled.
  bool correctionEnabled;

  /// `true` when game sound is enabled.
  bool soundEnabled;

  /// `true` when chat in network mode is enabled.
  bool onlineChatEnabled;

  /// Time limit per users move in local game modes.
  /// `0` means timer is disabled. Measured in seconds.
  int timeLimit;

  /// Defines game score calculation and winner checking strategy.
  ScoringType scoringType;

  /// Returns string containing JSON-encoded representation of score data.
  String get scoringData;

  /// Returns string containing legacy representation of score data.
  String get legacyScoringData;

  /// Last dictionary updates checking date.
  DateTime lastDictionaryCheckDate;

  /// Gets dictionary update checking interval.
  /// [DictionaryUpdatePeriod.NEVER] means don't fetch updates.
  DictionaryUpdatePeriod dictionaryUpdatePeriod;
}

/// Stub implementation that used for testing purpose
class InMemoryPreferences extends GamePreferences {
  @override
  Difficulty wordsDifficulty = Difficulty.EASY;

  @override
  bool correctionEnabled = false;

  @override
  bool soundEnabled = true;

  @override
  bool onlineChatEnabled = true;

  @override
  int timeLimit = 60;

  @override
  ScoringType scoringType = ScoringType.BY_SCORE;

  String get scoringData => "";

  String get legacyScoringData => "";

  @override
  DateTime lastDictionaryCheckDate = DateTime.now();

  @override
  DictionaryUpdatePeriod dictionaryUpdatePeriod =
      DictionaryUpdatePeriod.THREE_HOURS;
}
