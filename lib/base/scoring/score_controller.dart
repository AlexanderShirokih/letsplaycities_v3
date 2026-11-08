import 'dart:convert';

import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/collections_utils.dart';

typedef OnUpdateScoringData = void Function(ScoringSet scoringData);

/// Responsible for managing users score,
/// controlling achievements and player stats
class ScoreController {
  final GameMode _mode;
  final ScoringSet _allGroups;
  final ScoringType _scoringType;
  final OnUpdateScoringData _onUpdate;

  ScoreController(
    this._allGroups,
    this._scoringType,
    this._mode,
    this._onUpdate,
  );

  factory ScoreController.fromPrefs(GamePreferences prefs, GameMode mode) =>
      ScoreController(
        _getScoreData(prefs.scoringData),
        prefs.scoringType,
        mode,
        (newData) => prefs.scoringData = jsonEncode(newData.toJson()),
      );

  static ScoringSet _getScoreData(String scoringData) {
    if (scoringData.isEmpty) return ScoringSet.initial();

    final stored = ScoringSet.fromJson(jsonDecode(scoringData));
    final storedNames = stored.groups.map((group) => group.main.name).toSet();

    // Groups this version updates must exist, so missing ones start empty.
    return ScoringSet(
      groups: [
        ...stored.groups,
        ...ScoringSet.initial().groups.where(
          (group) => !storedNames.contains(group.main.name),
        ),
      ],
    );
  }

  /// Stores score and all statistic results to the storage by calling
  /// [OnUpdateScoringData] callback
  void commit() => _onUpdate(_allGroups);

  /// Used when [user]s move ended by accepting [word] during [moveTimeInMs] from move start
  /// Also updates combos for current user is player from `Map<ComboTypeIndex, ComboValue>`
  void onMoveFinished(
    User user,
    String word,
    int moveTimeInMs,
    Map<int, int> activeCombos,
  ) {
    if (_mode == GameMode.network) {
      _allGroups[groupOnline][fieldTime].asIntField().add(moveTimeInMs ~/ 1000);
    }

    user.increaseScore(_getPoints(word, moveTimeInMs));

    if (user is Player) {
      _updateLongestCities(user, word);
      _updateMostFrequentCities(word);
      _updateCombos(activeCombos);
    }
  }

  /// Used when the game has finished. Updates parts count stats.
  ///
  /// Games without score (last move wins) are counted too: nobody has points
  /// there, so only scored games that ended with no points are skipped.
  void onGameFinished(GameResult gameResult) {
    if (gameResult.hasScore && gameResult.owner.score <= 0) return;

    _allGroups[groupParts].main.asIntField().increase();
    _allGroups[groupParts][_translateGameMode(_mode)].asIntField().increase();

    if (_mode == GameMode.network) {
      switch (gameResult.matchResult) {
        case MatchResult.win:
          _allGroups[groupOnline][fieldWins].asIntField().increase();
          break;
        case MatchResult.lose:
          _allGroups[groupOnline][fieldLose].asIntField().increase();
          break;
        case MatchResult.draw:
          break;
      }
    }
  }

  void _updateLongestCities(User user, String word) =>
      _updateTop10By(groupBigCities, word, (w) => w.length, null);

  void _updateMostFrequentCities(String word) => _updateTop10By(
    groupFrequentCities,
    word,
    (_) => 1,
    (old, current) => old.clone(value: (old.value ?? 0) + (current.value ?? 0)),
  );

  void _updateCombos(Map<int, int> activeCombos) {
    for (final combo in activeCombos.entries) {
      _allGroups[groupCombo].child[combo.key].asIntField().max(combo.value);
    }
  }

  void _updateTop10By(
    String group,
    String word,
    int Function(String) defaultValue,
    PairedScoringField<String, int> Function(
      PairedScoringField<String, int> prev,
      PairedScoringField<String, int> curr,
    )?
    onMerge,
  ) {
    // Recalculate list. The whole list is ranked before it is cut to 10,
    // otherwise a new word (appended last) never gets into a full list.
    final distinct =
        (_allGroups[group].child
                    .cast<PairedScoringField<String, int>>()
                    .where(
                      (field) =>
                          field.hasValue() && field.key != emptyFieldValue,
                    )
                    .toList() +
                [PairedScoringField<String, int>('', word, defaultValue(word))])
            .distinctBy((field) => field.key ?? '', onDuplicate: onMerge)
            .toList(growable: false);

    // On equal values the word just played ranks first, so a new city can
    // replace an old one with the same value; other ties keep their order.
    final order = List.generate(distinct.length, (i) => i)
      ..sort((i, j) {
        final a = distinct[i], b = distinct[j];
        final byValue = (b.value ?? 0).compareTo(a.value ?? 0);
        if (byValue != 0) return byValue;
        if ((a.key == word) != (b.key == word)) return a.key == word ? -1 : 1;
        return i.compareTo(j);
      });
    final newList = order.map((i) => distinct[i]).toList(growable: false);

    // Update references
    _allGroups[group].child = newList
        .asMap()
        .map((i, word) => MapEntry(i, word.clone(name: '$fieldPairPrefix$i')))
        .values
        .take(10)
        .toList(growable: false);
  }

  int _getPoints(String word, int moveTime) {
    switch (_scoringType) {
      case ScoringType.lastMove:
        return 0;
      case ScoringType.byScore:
        return word.length;
      case ScoringType.byTime:
        final dt = ((40000 - moveTime) ~/ 2000);
        return 2 + (dt > 0 ? dt : 0);
    }
  }

  String _translateGameMode(GameMode mode) {
    switch (mode) {
      case GameMode.playerVsAndroid:
        return fieldAndroid;
      case GameMode.playerVsPlayer:
        return fieldPlayer;
      case GameMode.multiplayer:
        return fieldNetwork;
      case GameMode.network:
        return fieldOnline;
    }
  }
}
