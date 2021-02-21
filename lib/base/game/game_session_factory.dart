import 'package:lets_play_cities/base/dictionary.dart';
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
  static GameSession createForGameMode({
    required GamePreferences preferences,
    required GameConfig config,
    required ExclusionsService exclusions,
    required DictionaryService dictionary,
    required ScoreController scoreController,
    required void Function() onUserInputAccepted,
    required void Function() onUserMoveBegins,
  }) {
    final mode = config.gameMode;

    if (dictionary is! DictionaryDecorator) {
      throw ('DictionaryDecorator required!');
    }

    final usersList =
        config.usersListOverride ?? UsersList.forGameMode(mode, dictionary);

    final gameProcessorsStack = [
      TrustedEventsInterceptor(),
      FirstLetterChecker(),
      ExclusionsChecker(exclusions),
      DatabaseChecker(dictionary),
      ...(config.additionalEventHandlers ?? <EventHandler>[]),
      Endpoint(
        dictionary,
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
      externalEvents: config.externalEventSource,
    );
  }
}
