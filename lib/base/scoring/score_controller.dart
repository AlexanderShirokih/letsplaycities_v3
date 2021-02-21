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

  factory ScoreController.fromPrefs(
    GamePreferences prefs,
    GameMode mode,
  ) =>
      ScoreController(
        _getScoreData(prefs.scoringData),
        prefs.scoringType,
        mode,
        (newData) => prefs.scoringData = jsonEncode(newData.toJson()),
      );

  static ScoringSet _getScoreData(dynamic scoringData) => scoringData.isEmpty
      ? ScoringSet.initial()
      : ScoringSet.fromJson(jsonDecode(scoringData));

  /// Stores score and all statistic results to the storage by calling
  /// [OnUpdateScoringData] callback
  void commit() => _onUpdate(_allGroups);

  /// Used when [user]s move ended by accepting [word] during [moveTimeInMs] from move start
  /// Also updates combos for current user is player from Map<ComboTypeIndex, ComboValue>
  void onMoveFinished(
    User user,
    String word,
    int moveTimeInMs,
    Map<int, int> activeCombos,
  ) {
    if (_mode == GameMode.network) {
      _allGroups[G_ONLINE][F_TIME].asIntField().add(moveTimeInMs ~/ 1000);
    }

    user.increaseScore(_getPoints(word, moveTimeInMs));

    if (user is Player) {
      _updateLongestCities(user, word);
      _updateMostFrequentCities(word);
      _updateCombos(activeCombos);
    }
  }

  /// Used when the game has finished. Updates parts count stats.
  void onGameFinished(GameResult gameResult) {
    if (!gameResult.hasScore || gameResult.owner.score <= 0) return;

    _allGroups[G_PARTS].main.asIntField().increase();
    _allGroups[G_PARTS][_translateGameMode(_mode)].asIntField().increase();

    if (_mode == GameMode.network) {
      switch (gameResult.matchResult) {
        case MatchResult.WIN:
          _allGroups[G_ONLINE][F_WINS].asIntField().increase();
          break;
        case MatchResult.LOSE:
          _allGroups[G_ONLINE][F_LOSE].asIntField().increase();
          break;
        case MatchResult.DRAW:
          break;
      }
    }
  }

  void _updateLongestCities(User user, String word) =>
      _updateTop10By(G_BIG_CITIES, word, (w) => w.length, null);

  void _updateMostFrequentCities(String word) => _updateTop10By(
      G_FRQ_CITIES,
      word,
      (_) => 1,
      (old, current) =>
          old.clone(value: old.value ?? 0 + (current.value ?? 0)));

  void _updateCombos(Map<int, int> activeCombos) =>
      activeCombos.entries.forEach((MapEntry<int, int> combo) =>
          _allGroups[G_COMBO].child[combo.key].asIntField().max(combo.value));

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
    // Recalculate list
    final newList = (_allGroups[group]
                .child
                .cast<PairedScoringField<String, int>>()
                .where((field) => field.hasValue() && field.key != V_EMPTY_S)
                .toList() +
            [PairedScoringField<String, int>('', word, defaultValue(word))])
        .distinctBy((field) => field.key ?? '', onDuplicate: onMerge)
        .take(10)
        .toList(growable: false)
          ..sort((a, b) => b.value?.compareTo(a.value ?? 0) ?? 0);

    // Update references
    _allGroups[group].child = newList
        .asMap()
        .map((i, word) => MapEntry(i, word.clone(name: '$F_P$i')))
        .values
        .take(10)
        .toList(growable: false);
  }

  int _getPoints(String word, int moveTime) {
    switch (_scoringType) {
      case ScoringType.LAST_MOVE:
        return 0;
      case ScoringType.BY_SCORE:
        return word.length;
      case ScoringType.BY_TIME:
        final dt = ((40000 - moveTime) ~/ 2000);
        return 2 + dt > 0 ? dt : 0;
    }
  }

  String _translateGameMode(GameMode mode) {
    switch (mode) {
      case GameMode.playerVsAndroid:
        return F_ANDROID;
      case GameMode.playerVsPlayer:
        return F_PLAYER;
      case GameMode.multiplayer:
        return F_NETWORK;
      case GameMode.network:
        return F_ONLINE;
    }
  }
}
