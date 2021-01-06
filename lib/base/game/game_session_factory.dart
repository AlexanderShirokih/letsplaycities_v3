import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:meta/meta.dart';

import 'game_config.dart';
import 'handlers.dart';
import 'management.dart';

/// Factory class used to create [GameSession] instances
class GameSessionFactory {
  /// Creates [GameSession] depending on given parameters.
  /// Note that [GameConfig] will override some parameters.
  static GameSession createForGameMode({
    @required GamePreferences preferences,
    @required GameConfig config,
    @required ExclusionsService exclusions,
    @required DictionaryService dictionary,
    @required ScoreController scoreController,
    @required void Function() onUserInputAccepted,
  }) {
    final mode = config.gameMode;
    final usersList =
        config.usersList ?? UsersList.forGameMode(mode, dictionary);

    final gameProcessorsStack = [
      TrustedEventsInterceptor(),
      FirstLetterChecker(),
      ExclusionsChecker(exclusions),
      DatabaseChecker(dictionary),
      ...(config.additionalEventHandlers ?? <EventHandler>[]),
      Endpoint(dictionary, onUserInputAccepted, scoreController),
    ];

    return GameSession(
      mode: mode,
      usersList: usersList,
      scoringType: preferences.scoringType,
      eventChannel: ProcessingEventChannel(gameProcessorsStack),
      timeLimit: config.timeLimit ?? preferences.timeLimit,
    );
  }
}
