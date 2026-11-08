import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/game_session.dart';
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
  }) {
    final mode = config.gameMode;

    if (dictionary is! DictionaryDecorator) {
      throw ('DictionaryDecorator required!');
    }

    final usersList =
        config.usersListOverride ??
        UsersList.forGameMode(mode, dictionary, playerNames);

    final gameProcessorsStack = [
      TrustedEventsInterceptor(),
      FirstLetterChecker(),
      ExclusionsChecker(exclusions),
      DatabaseChecker(dictionary),
      ...(config.additionalEventHandlers ?? <EventHandler>[]),
      Endpoint(
        dictionary,
        codeOverrides,
        onUserInputAccepted,
        onUserMoveBegins,
        scoreController,
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
    );
  }
}
