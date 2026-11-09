import 'dart:math';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/player/skip_move_exception.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/game/player/user.dart';

/// Represents logic of Android player.
/// [PlayerData] model class that contains info about user.
/// [PictureSource] represents android's picture.
class Android extends User {
  static const _kAndroidAvatarPath = 'assets/images/android_big.png';

  final DictionaryDecorator _dictionary;

  /// How long Android waits before it answers
  final Duration _moveDelay;

  /// Count of moves before Android surrenders
  int _estimatedMoves;

  /// Picks the city of a Route game, `null` when there is none; Android then
  /// skips the move and never surrenders
  final Future<String?> Function(String firstChar)? _routeWord;

  Android(
    this._dictionary,
    String androidName, {
    this._moveDelay = const Duration(milliseconds: 1500),
    Random? random,
    this._routeWord,
  }) : _estimatedMoves = _calculateEstimatedMoves(
         _dictionary.difficulty.index,
         random ?? Random(),
       ),
       super(
         accountInfo: LocalAccountInfo(
           name: androidName,
           picture: const AssetPictureSource(_kAndroidAvatarPath),
         ),
         isTrusted: true,
         comboSystem: ComboSystem(canUseQuickTime: false),
       );

  @override
  Future<String> onCreateWord(String firstChar) async {
    final routeWord = _routeWord;

    if (routeWord != null) {
      // Without a city the move is skipped at once, without the pause
      final city = await routeWord(firstChar);
      if (city == null) throw SkipMoveException(this);

      await Future.delayed(_moveDelay);
      return city;
    }

    await Future.delayed(_moveDelay);

    final word = await _dictionary.getRandomWord(firstChar);

    if (_estimatedMoves-- <= 0 || word.isEmpty) {
      throw SurrenderException(this, false);
    }

    return word;
  }

  static int _calculateEstimatedMoves(int difficultyIndex, Random random) {
    var estimatedMoves = (20.0 + difficultyIndex.toDouble() / 3.0 * 70).toInt();
    return (estimatedMoves * (1.0 + random.nextDouble() * 0.35)).toInt();
  }
}
