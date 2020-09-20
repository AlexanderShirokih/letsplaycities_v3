import 'dart:async';
import 'dart:math';

import 'package:lets_play_cities/base/auth.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// User that controls by players keyboard
class Player extends User {
  static final idLimit = pow(2, 32);

  static Random _rnd = Random();

  final StreamController<String> _userInput =
  StreamController<String>.broadcast();

  @override
  Future<void> close() => _userInput.close().then((_) => super.close());

  Player(PlayerData playerData, [ClientAccountInfo accountInfo])
      : super(
    playerData: playerData,
    comboSystem: ComboSystem(canUseQuickTime: true),
    accountInfo: accountInfo ??
        ClientAccountInfo.basic(
            playerData.name, -_rnd.nextInt(idLimit) - 2),
    isTrusted: false,
  );

  @override
  Future<String> onCreateWord(String firstChar) {
    return _userInput.stream.first
        .catchError((_) => throw SurrenderException(this, true));
  }

  /// Used to pass players input to [onCreateWord]
  void onUserInput(String userInput) {
    _userInput.add(formatCity(userInput));
  }
}
