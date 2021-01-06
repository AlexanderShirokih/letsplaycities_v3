import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/player/users_list.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/handlers/event_processor.dart';

/// Configuration class to used start the game
class GameConfig {
  /// Time limit per move (in seconds).
  /// If `null` then value from preferences will used.
  final int timeLimit;

  /// Game mode
  final GameMode gameMode;

  /// Game participants
  final UsersList usersList;

  /// A list of additional event handlers.
  /// Will be appended before [Endpoint] handler.
  final List<EventHandler> additionalEventHandlers;

  const GameConfig({
    @required this.gameMode,
    this.timeLimit,
    this.usersList,
    this.additionalEventHandlers,
  }) : assert(gameMode != null);
}
