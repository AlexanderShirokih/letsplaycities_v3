import 'dart:convert';

import 'package:lets_play_cities/base/game/scoring/scoring_fields.dart';
import 'package:lets_play_cities/base/game/scoring/scoring_type.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';
import 'scoring_groups.dart';

/// Responsible for managing users score,
/// controlling achievements and player stats
class ScoreController {
  final ScoringSet _allGroups;
  final ScoringType _scoringType;

  int _playerMovesInGame = 0;

  ScoreController(this._allGroups, this._scoringType);

  factory ScoreController.fromPrefs(GamePreferences prefs) {
    final legacyScoring = prefs.legacyScoringData;
    final scoreSet = legacyScoring.isNotEmpty
        ? ScoringSet.fromLegacyString(legacyScoring)
        : _getScoreData(prefs.scoringData);
    return ScoreController(scoreSet, prefs.scoringType);
  }

  static ScoringSet _getScoreData(dynamic scoringData) => scoringData.isEmpty
      ? ScoringSet.initial()
      : ScoringSet.fromJson(jsonDecode(scoringData));

  /// Used when [user]s move ended by accepting [word] during [moveTimeInMs] from move start
  Future<void> onMoveFinished(User user, String word, int moveTimeInMs) async {
    _allGroups[G_ONLINE][F_TIME].asIntField().add(moveTimeInMs ~/ 1000);

    if (user is Player) _playerMovesInGame++;

    user.increaseScore(_getPoints(word, moveTimeInMs));

    if (user is Player) {
      _updateLongestCities(user, word);
      _updateMostFrequentCities(word);
    }

    // TODO: _checkCombos(user, moveTimeInMs, word);
  }

  void _updateLongestCities(User user, String word) {
    // Find the most longest cities
    final newList = (_allGroups[G_BIG_CITIES]
                .child
                .cast<PairedScoringField<String, int>>()
                .where((field) => field.hasValue() && field.key != V_EMPTY_S)
                .map((e) => e.key)
                .toList() +
            [word])
        .toSet()
        .toList(growable: false);

    newList.sort((a, b) => a.compareTo(b));

    // Update references
    _allGroups[G_BIG_CITIES].child = newList
        .asMap()
        .map((i, word) =>
            MapEntry(i, PairedScoringField("$F_P$i", word, word.length)))
        .values
        .take(10)
        .toList(growable: false);
  }

  void _updateMostFrequentCities(String lastWord) {
    //TODO: implement
  }

  int _getPoints(String word, int moveTime) {
    switch (_scoringType) {
      case ScoringType.LAST_MOVE:
        return 0;
      case ScoringType.BY_SCORE:
        return word.length;
      case ScoringType.BY_TIME:
        final dt = ((40000 - moveTime) / 2000);
        return 2 + dt > 0 ? dt : 0;
    }
    throw ("Bad state");
  }
}
