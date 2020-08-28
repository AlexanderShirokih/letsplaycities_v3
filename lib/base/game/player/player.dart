import 'dart:async';

import 'package:lets_play_cities/base/auth.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// User that controller by players keyboard
class Player extends User {
  static const _kDefaultPlayerId = -1;

  // TODO: Close stream
  final StreamController<String> _userInput =
      StreamController<String>.broadcast();

  Player(PlayerData playerData, [ClientAccountInfo accountInfo])
      : super(
          playerData: playerData,
          accountInfo: accountInfo ??
              ClientAccountInfo.basic(playerData.name, _kDefaultPlayerId),
          isTrusted: false,
        );

  @override
  Future<String> onCreateWord(String firstChar) {
    return _userInput.stream.first;
  }

  /// Used to pass players input to [onCreateWord]
  void onUserInput(String userInput) {
    _userInput.add(formatCity(userInput));
  }
}
