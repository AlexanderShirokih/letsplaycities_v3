import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/geo/geo_index.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/debouncer.dart';

class GameSessionRepository {
  // Only words are debounced: the [Debouncer] drops the call it has deferred
  // when it is run again, and every chat message must be delivered.
  final Debouncer _userInputDebounce = Debouncer(
    const Duration(milliseconds: 1000),
  );

  final GameSession _session;

  final RouteData? _routeData;

  /// [routeData] is the data of a Route game
  GameSessionRepository(this._session, {this._routeData});

  RouteRules? get _routeRules => switch (_session.rules) {
    final RouteRules rules => rules,
    _ => null,
  };

  /// The route now and after every move, `null` outside a Route game
  Stream<RouteState>? get routeStates => _routeRules?.states;

  /// The route now, `null` outside a Route game
  RouteState? get routeState => _routeRules?.state;

  /// The world map of a Route game
  WorldOutline? get world => _routeData?.world;

  /// The city coordinates of a Route game
  GeoIndex? get geo => _routeData?.geo;

  Stream<WordCheckingResult> get wordCheckingResults =>
      _session.wordCheckingResults;

  /// `true` if this game mode supports players help
  bool get helpAvailable => _session.mode == GameMode.playerVsAndroid;

  /// When the next hint of this game can be taken; `null` before the first
  /// hint
  final hintReadyAt = ValueNotifier<DateTime?>(null);

  /// `true` if this game mode supports messaging
  bool get messagingAvailable =>
      _session.mode == GameMode.network &&
      _session.usersList.all.every((user) => user.isMessagesAllowed);

  /// Time limit in seconds per move, `0` when the moves are not timed
  int get timeLimit => _session.timeLimit;

  /// Returns latest accepted word
  String get lastAcceptedWord => _session.lastAcceptedWord;

  /// Cities and messages of this game. There is one instance per session, so
  /// the played items survive rebuilds of the widgets that show them.
  late final GameItemsRepository gameItemsRepository = GameItemsRepository(
    _session.inputEvents,
  );

  /// Returns [gameItemsRepository]; it does not create a new instance.
  GameItemsRepository createGameItemsRepository() => gameItemsRepository;

  /// Creates new instance of [GameServiceEventsRepository]
  GameServiceEventsRepository createGameServiceEventsRepository() =>
      GameServiceEventsRepository(_session.inputEvents);

  /// Returns a user attached to the [position].
  User getUserByPosition(Position position) =>
      _session.getUserByPosition(position);

  /// Finished the game and surrenders current player
  Future surrender() => _session.surrender();

  /// Called to dispose internal StreamControllers
  Future finish() async {
    _userInputDebounce.cancel();
    await _session.cancel();
  }

  /// Runs moves loop
  /// When the game finishes returns [GameResult]
  Future<GameResult> run() => _session.runMoves();

  /// Dispatches input word to the game session
  void sendInputWord(String input) {
    _userInputDebounce.run(() => _session.deliverUserInput(input));
  }

  /// Dispatches input message to the game session at once
  void sendChatMessage(String message) {
    _session.deliverUserMessage(message);
  }
}
