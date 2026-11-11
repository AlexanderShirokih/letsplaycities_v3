import 'dart:math';

import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/game/rules/classic_rules.dart';
import 'package:lets_play_cities/base/game/rules/match_rules.dart';
import 'package:lets_play_cities/base/game/rules/route_city_picker.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

import 'game_config.dart';
import 'handlers.dart';
import 'management.dart';

/// Factory class used to create [GameSession] instances
class GameSessionFactory {
  /// Creates [GameSession] depending on given parameters.
  /// Note that [GameConfig] will override some parameters.
  /// [playerNames] name the users of a game on one device.
  /// A game of two players on one device waits at a [TurnGate] before each
  /// move.
  /// A Route game is played on the dictionary of [routeData], which it
  /// requires.
  static GameSession createForGameMode({
    required GamePreferences preferences,
    required GameConfig config,
    required ExclusionsService exclusions,
    required DictionaryService dictionary,
    required CountryCodeOverrides codeOverrides,
    required ScoreController scoreController,
    required AchievementsService achievements,
    required DefaultPlayerNames playerNames,
    required void Function() onUserInputAccepted,
    required void Function() onUserMoveBegins,
    RouteData? routeData,
  }) {
    final mode = config.gameMode;

    if (dictionary is! DictionaryDecorator) {
      throw ('DictionaryDecorator required!');
    }

    final MatchRules rules;
    final DictionaryDecorator gameDictionary;
    Future<String?> Function(String firstChar)? routeWord;

    switch (config.variant) {
      case GameVariant.classic:
        rules = ClassicRules(scoreController);
        gameDictionary = dictionary;

      case GameVariant.route:
        if (routeData == null) {
          throw ArgumentError.notNull('routeData');
        }

        final routeRules = RouteRules(routeData.geo, 2);
        final routeDictionary = DictionaryDecorator(
          routeData.dictionary,
          preferences,
        );
        final random = Random();

        rules = routeRules;
        gameDictionary = routeDictionary;
        routeWord = (firstChar) async => pickRouteCity(
          candidates: routeDictionary.getCandidates(firstChar),
          from: routeRules.lastPoint,
          geo: routeData.geo,
          difficulty: preferences.wordsDifficulty,
          random: random,
        );
    }

    final usersList =
        config.usersListOverride ??
        UsersList.forGameMode(
          mode,
          gameDictionary,
          playerNames,
          routeWord: routeWord,
        );

    final gameProcessorsStack = [
      TrustedEventsInterceptor(),
      FirstLetterChecker(),
      ExclusionsChecker(exclusions),
      DatabaseChecker(gameDictionary),
      ...(config.additionalEventHandlers ?? <EventHandler>[]),
      Endpoint(
        gameDictionary,
        codeOverrides,
        onUserInputAccepted,
        onUserMoveBegins,
        rules,
      ),
    ];

    return GameSession(
      mode: mode,
      usersList: usersList,
      scoreController: scoreController,
      scoringType: preferences.scoringType,
      eventChannel: ProcessingEventChannel(gameProcessorsStack),
      timeLimit: config.timeLimitOverride ?? preferences.timeLimit,
      achievements: achievements,
      wordsDifficulty: () => preferences.wordsDifficulty,
      externalEvents: config.externalEventSource,
      turnGate: mode == GameMode.playerVsPlayer ? TurnGate() : null,
      serverAuthoritative: config.serverAuthoritative,
      rules: rules,
    );
  }
}
