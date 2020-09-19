import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/user.dart';
import 'package:lets_play_cities/base/game/handlers.dart';

/// Checks the [RawWordEvent]s word for existence in the game dictionary.
/// Emits:
///   [NotFound] - if word wasn't found in dictionary and haven't
/// corrections(or they disabled);
///   [Corrections] - if word in this state wasn't found in dictionary but has
/// correction variants
///   [AlreadyUsed] - if word was already used during this game
///   [Accepted] - if word wasn't used before and exists in the database.
class DatabaseChecker extends TypedEventHandler<RawWordEvent> {
  final DictionaryService _dictionary;

  DatabaseChecker(this._dictionary);

  @override
  Stream<GameEvent> processTypedEvent(RawWordEvent event) async* {
    // Check for existence in the database and corrections
    var checkingResult = await _checkInDatabase(event.word, event.owner);

    if (checkingResult is NotFound && checkingResult.word.length > 3) {
      var corrections = await _dictionary.getCorrectionVariants(event.word);
      switch (corrections.length) {
        case 0:
          yield NotFound(event.word);
          break;
        case 1:
          yield Accepted(corrections.first, event.owner);
          break;
        default:
          yield Corrections(corrections);
          break;
      }
      return;
    }

    yield checkingResult;
  }

  Future<WordCheckingResult> _checkInDatabase(String input, User owner) async {
    var word = input;
    var attempts = 2;

    do {
      var checkingResult = await _dictionary.checkCity(word);
      if (checkingResult != null) {
        switch (checkingResult) {
          case CityResult.OK:
            return Accepted(word, owner);
          case CityResult.CITY_NOT_FOUND:
            word = word.replaceAll(" ", "-");
            break;
          case CityResult.ALREADY_USED:
            return AlreadyUsed(word);
        }
      }
    } while (--attempts > 0);

    return NotFound(word);
  }
}
