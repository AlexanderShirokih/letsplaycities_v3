import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management/game_events.dart';
import 'package:lets_play_cities/base/game/management/word_checking_result.dart';

/// Intercepts [Accepted] words, commits them to the database.
class LocalEndpoint extends TypedEventHandler<Accepted> {
  final DictionaryService _dictionaryService;

  LocalEndpoint(this._dictionaryService) : assert(_dictionaryService != null);

  @override
  Stream<GameEvent> processTypedEvent(Accepted event) async* {
    _dictionaryService.markUsed(event.word);
    yield event;
  }
}
