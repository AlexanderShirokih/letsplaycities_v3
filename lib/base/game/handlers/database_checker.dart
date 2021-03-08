import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/user.dart';

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
      var corrections = _dictionary
          .getCorrectionVariants(event.word)
          .timeout(Duration(seconds: 3), onTimeout: (sink) => sink.close());

      final allCorrections = <String>{};

      await for (final correction in corrections) {
        allCorrections.add(correction);
        yield Corrections(allCorrections);
      }

      if (allCorrections.isEmpty) {
        yield NotFound(event.word);
      } else if (allCorrections.length == 1) {
        yield Accepted(allCorrections.first, event.owner);
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
      switch (checkingResult) {
        case CityResult.OK:
          return Accepted(word, owner);
        case CityResult.CITY_NOT_FOUND:
          word = word.replaceAll(' ', '-');
          break;
        case CityResult.ALREADY_USED:
          return AlreadyUsed(word);
      }
    } while (--attempts > 0);

    return NotFound(word);
  }
}
