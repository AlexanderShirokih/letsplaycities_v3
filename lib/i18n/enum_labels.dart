/// Texts for the values of app enums. Each switch is exhaustive, so a new
/// enum value does not compile until it has a text.
library;

import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/dictionary/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_update_period.dart';
import 'package:lets_play_cities/base/game/combo/combo_type.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management/game_events.dart';
import 'package:lets_play_cities/base/scoring/scoring_type.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

extension AchievementLabel on Achievement {
  String label(Translations t) => switch (this) {
    Achievement.write15Cities => t.achievements.write15Cities,
    Achievement.use3Tips => t.achievements.use3Tips,
    Achievement.add1Friend => t.achievements.add1Friend,
    Achievement.playInHardMode => t.achievements.playInHardMode,
    Achievement.reachScore1000Pts => t.achievements.reachScore1000Pts,
    Achievement.write80Cities => t.achievements.write80Cities,
    Achievement.loginViaSocial => t.achievements.loginViaSocial,
    Achievement.changeTheme => t.achievements.changeTheme,
    Achievement.write50CitiesInGame => t.achievements.write50CitiesInGame,
    Achievement.playOnline3Times => t.achievements.playOnline3Times,
    Achievement.use30Tips => t.achievements.use30Tips,
    Achievement.reachScore5000Pts => t.achievements.reachScore5000Pts,
    Achievement.write500Cities => t.achievements.write500Cities,
    Achievement.write100CitiesInGame => t.achievements.write100CitiesInGame,
    Achievement.reachScore25000Pts => t.achievements.reachScore25000Pts,
  };
}

extension ComboTypeLabel on ComboType {
  String label(Translations t) => switch (this) {
    ComboType.quickTime => t.game.combos.quickTime,
    ComboType.shortWord => t.game.combos.shortWord,
    ComboType.longWord => t.game.combos.longWord,
    ComboType.sameCountry => t.game.combos.sameCountry,
    ComboType.differentCountries => t.game.combos.differentCountries,
  };
}

extension MatchResultLabel on MatchResult {
  String label(Translations t) => switch (this) {
    MatchResult.win => t.gameResults.winTitle,
    MatchResult.lose => t.gameResults.loseTitle,
    MatchResult.draw => t.gameResults.drawTitle,
  };
}

extension DifficultyLabel on Difficulty {
  String label(Translations t) => switch (this) {
    Difficulty.easy => t.settings.difficulty.easy,
    Difficulty.medium => t.settings.difficulty.medium,
    Difficulty.hard => t.settings.difficulty.hard,
  };
}

extension ScoringTypeLabel on ScoringType {
  String label(Translations t) => switch (this) {
    ScoringType.byScore => t.settings.scoringType.byScore,
    ScoringType.byTime => t.settings.scoringType.byTime,
    ScoringType.lastMove => t.settings.scoringType.lastMove,
  };
}

extension DictionaryUpdatePeriodLabel on DictionaryUpdatePeriod {
  String label(Translations t) => switch (this) {
    DictionaryUpdatePeriod.never => t.settings.dictUpdPeriod.never,
    DictionaryUpdatePeriod.threeHours => t.settings.dictUpdPeriod.threeHours,
    DictionaryUpdatePeriod.daily => t.settings.dictUpdPeriod.daily,
  };
}

extension MoveFinishTypeLabel on MoveFinishType {
  /// How [name] ended the game, as the game results screen says it.
  ///
  /// A game does not end with a completed move, so
  /// [MoveFinishType.completed] throws, as the screen did before.
  String finishDescription(Translations t, String name) => switch (this) {
    MoveFinishType.timeout => t.gameResults.descTimeout(name: name),
    MoveFinishType.disconnected => t.gameResults.descDisconnected(name: name),
    MoveFinishType.surrender => t.gameResults.descSurrender(name: name),
    MoveFinishType.replaced => t.online.replaced,
    MoveFinishType.completed => throw StateError('Unknown move finish type!'),
  };
}
