import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/handlers/event_processor.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/users_list.dart';
import 'package:lets_play_cities/base/game_session.dart';

/// Configuration class to used start the game
class GameConfig {
  /// Time limit per move (in seconds).
  /// If `null` then value from preferences will used.
  final int? timeLimitOverride;

  /// Game mode
  final GameMode gameMode;

  /// Game participants overrides
  final UsersList? usersListOverride;

  /// A list of additional event handlers.
  /// Will be appended before [Endpoint] handler.
  final List<EventHandler>? additionalEventHandlers;

  /// Additional stream with [GameEvent]s
  final Stream<GameEvent> Function(GameSession)? externalEventSource;

  /// `true` is the game running from local game server
  final bool isLocalhost;

  const GameConfig({
    required this.gameMode,
    this.timeLimitOverride,
    this.usersListOverride,
    this.additionalEventHandlers,
    this.externalEventSource,
    this.isLocalhost = true,
  });
}
