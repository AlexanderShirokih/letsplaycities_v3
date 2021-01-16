import 'dart:async';

import 'package:lets_play_cities/base/game/combo/combo_system.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';

/// The user by the other side
class RemotePlayer extends User {
  final RemoteGameClient _remoteGameClient;

  @override
  Future<void> close() =>
      _remoteGameClient.disconnect().then((_) => super.close());

  RemotePlayer(AdvancedAccountInfo accountInfo, this._remoteGameClient)
      : super(
          comboSystem: ComboSystem(canUseQuickTime: true),
          accountInfo: accountInfo,
          isTrusted: true,
        );

  @override
  Future<String> onCreateWord(String firstChar) {
    return _remoteGameClient
        .getInputWords(accountInfo as AdvancedAccountInfo)
        .first
        .catchError((_) => throw SurrenderException(this, true));
  }
}
