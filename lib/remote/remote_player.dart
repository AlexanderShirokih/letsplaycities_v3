import 'dart:async';

import 'package:lets_play_cities/base/game/combo/combo_system.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';

/// The user by the other side: its moves are the words that the server
/// accepted from it
class RemotePlayer extends User {
  final RemoteGame _game;

  RemotePlayer(AdvancedAccountInfo accountInfo, this._game)
    : super(
        comboSystem: ComboSystem(canUseQuickTime: true),
        accountInfo: accountInfo,
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) => _game.nextOpponentWord();

  /// Leaves the game unless it is over; the shared connection stays open
  @override
  Future<void> close() async {
    await _game.quit();
    await super.close();
  }
}
