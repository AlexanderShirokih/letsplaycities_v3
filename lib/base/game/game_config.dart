import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/users_list.dart';
import 'package:lets_play_cities/base/game_session.dart';

/// The rules a game is played by
enum GameVariant {
  /// The classic game of cities
  classic,

  /// The route: the players go from city to city and count the kilometres
  route,
}

/// Configuration class to used start the game
class GameConfig {
  /// Time limit per move (in seconds).
  /// If `null` then value from preferences will used.
  final int? timeLimitOverride;

  /// Game mode
  final GameMode gameMode;

  /// The rules the game is played by
  final GameVariant variant;

  /// Game participants overrides
  final UsersList? usersListOverride;

  /// A list of additional event handlers.
  /// Will be appended before [Endpoint] handler.
  final List<EventHandler>? additionalEventHandlers;

  /// Additional stream with [GameEvent]s
  final Stream<GameEvent> Function(GameSession)? externalEventSource;

  /// `true` when a server judges the moves, runs the clock and ends the game:
  /// the network game and the LAN game
  bool get serverAuthoritative => gameMode.isServerAuthoritative;

  const GameConfig({
    required this.gameMode,
    this.variant = GameVariant.classic,
    this.timeLimitOverride,
    this.usersListOverride,
    this.additionalEventHandlers,
    this.externalEventSource,
  });
}
