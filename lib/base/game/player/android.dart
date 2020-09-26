import 'dart:math';

import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/player/user.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';

/// Represents logic of Android player.
/// [PlayerData] model class that contains info about user.
/// [PictureSource] represents android's picture.
class Android extends User {
  static const _kAndroidAvatarPath = 'assets/images/android_big.png';

  final DictionaryDecorator _dictionary;

  /// Count of moves before Android surrenders
  int _estimatedMoves;

  Android(
    this._dictionary,
    String androidName,
  )   : _estimatedMoves =
            _calculateEstimatedMoves(_dictionary.difficulty.index),
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
    await Future.delayed(Duration(milliseconds: 1500));

    final word = await _dictionary.getRandomWord(firstChar);

    if (_estimatedMoves-- <= 0 || word.isEmpty) {
      throw SurrenderException(this, false);
    }

    return word;
  }

  static int _calculateEstimatedMoves(int difficultyIndex) {
    var estimatedMoves = (20.0 + difficultyIndex.toDouble() / 3.0 * 70).toInt();
    return (estimatedMoves * (1.0 + Random().nextDouble() * 0.35)).toInt();
  }
}
