import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/player.dart';
import 'package:lets_play_cities/base/game/scoring/score_controller.dart';

/// User as callback hook to notify UI that word is accepted and input fields
/// can be cleared.
typedef OnUserInputAccepted = void Function();

/// Intercepts [Accepted] words, commits them to the database
/// and attaches country codes.
class LocalEndpoint extends EventHandler {
  /// Handles users scores and checks the winner
  final ScoreController _scoreController;

  final DictionaryService _dictionaryService;

  final OnUserInputAccepted _onUserInputAccepted;

  DateTime _currentUserStartTime;

  LocalEndpoint(
      this._dictionaryService, this._onUserInputAccepted, this._scoreController)
      : assert(_dictionaryService != null),
        assert(_onUserInputAccepted != null);

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    if (event is OnFirstCharChanged) _currentUserStartTime = DateTime.now();

    if (event is Accepted) {
      _dictionaryService.markUsed(event.word);

      yield event.clone(
          status: CityStatus.OK,
          countryCode: _dictionaryService.getCountryCode(event.word));

      if (event.owner is Player) _onUserInputAccepted();

      await _scoreController.onMoveFinished(
        event.owner,
        event.word,
        DateTime.now().difference(_currentUserStartTime).inMilliseconds,
      );
    } else
      yield event;
  }
}
