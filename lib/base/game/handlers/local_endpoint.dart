import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/player.dart';

/// User as callback hook to notify UI that word is accepted and input fields
/// can be cleared.
typedef OnUserInputAccepted = void Function();

/// Intercepts [Accepted] words, commits them to the database.
class LocalEndpoint extends TypedEventHandler<Accepted> {
  final DictionaryService _dictionaryService;

  final OnUserInputAccepted _onUserInputAccepted;

  LocalEndpoint(this._dictionaryService, this._onUserInputAccepted)
      : assert(_dictionaryService != null),
        assert(_onUserInputAccepted != null);

  @override
  Stream<GameEvent> processTypedEvent(Accepted event) async* {
    _dictionaryService.markUsed(event.word);
    yield event;
    if (event.owner is Player) _onUserInputAccepted();
  }
}
