import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/player.dart';
import 'package:lets_play_cities/base/scoring.dart';

/// Callback hook used to notify UI that word is accepted and input fields
/// can be cleared.
typedef OnUserInputAccepted = void Function();

/// Callback hook used to notify UI that *player* move begins
typedef OnUserMoveBegins = void Function();

/// Intercepts [Accepted] words, commits them to the database
/// and attaches country codes.
class Endpoint extends EventHandler {
  /// Handles users scores and checks the winner
  final ScoreController _scoreController;

  final DictionaryService _dictionaryService;

  final OnUserInputAccepted _onUserInputAccepted;

  final OnUserMoveBegins _onUserMoveBegins;

  late DateTime _currentUserStartTime;

  Endpoint(
    this._dictionaryService,
    this._onUserInputAccepted,
    this._onUserMoveBegins,
    this._scoreController,
  );

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    if (event is OnFirstCharChanged) {
      _currentUserStartTime = DateTime.now();
    }

    if (event is OnUserSwitchedEvent) {
      if (event.nextUser is Player) {
        _onUserMoveBegins();
      }
    }

    if (event is Accepted) {
      _dictionaryService.markUsed(event.word);

      final countryCode = _dictionaryService.getCountryCode(event.word);
      final comboSystem = event.owner.comboSystem;
      final deltaTime =
          DateTime.now().difference(_currentUserStartTime).inMilliseconds;

      yield event.clone(status: CityStatus.OK, countryCode: countryCode);

      if (event.owner is Player) _onUserInputAccepted();

      comboSystem.addCity(
          CityComboInfo.fromMoveParams(deltaTime, event.word, countryCode));

      _scoreController.onMoveFinished(
        event.owner,
        event.word,
        deltaTime,
        comboSystem.activeCombos
            .map((key, value) => MapEntry<int, int>(key.index, value)),
      );
    } else {
      yield event;
    }
  }
}
