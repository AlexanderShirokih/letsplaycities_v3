import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/player/user.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/user_input_consumer.dart';
import 'package:lets_play_cities/base/game/word_checking_result.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import '../game_facade.dart';

class Player extends User implements UserInputConsumer {
  final StreamController<String> _userInput = StreamController<String>();

//  final AbstractEventChannel _eventChannel;
  final GameFacade _gameFacade;

  String _firstChar = "";

  Player(
    this._gameFacade,
//    this._eventChannel,
    PlayerData playerData,
  ) : super(
            playerData,
            (playerData.accountInfo.pictureUri != null)
                ? NetworkPictureSource(
                    playerData.accountInfo.pictureUri?.toString())
                : null);

  @override
  Stream<ResultWithCity> onMakeMove(String firstChar) {
    _firstChar = firstChar;

    //TODO: Send city to the channel
    return _userInput.stream.map(
      (event) => ResultWithCity(
        wordResult: WordResult.ACCEPTED,
        city: event,
        identity: UserIdIdentity(0),
      ),
    );
  }

  @override
  Stream<WordCheckingResult> onUserInput(String userInput) async* {
    String input = formatCity(userInput);

    if (input.isEmpty) return;

    await for (var event in _checkUserInput(input)) {
      if (event is Accepted) _userInput.add(event.word);
      yield event;
    }
  }

  _checkUserInput(String input) async* {
    // Check the first matter matches
    if (!_checkFirstLetterMatches(input)) {
      yield WrongLetter(_firstChar);
      return;
    }

    // Check the city in the exclusions list
    var exclusion = _gameFacade.checkForExclusion(input);
    if (exclusion != null) {
      yield Exclusion(exclusion);
      return;
    }

    // Check existence in the database and corrections
    var checkingResult = await _checkInDatabase(input);

    if (checkingResult is NotFound && checkingResult.word.length > 3) {
      var corrections = await _gameFacade.getCorrections(input);
      switch (corrections.length) {
        case 0:
          yield NotFound(input);
          break;
        case 1:
          yield Accepted(corrections[0]);
          break;
        default:
          yield Corrections(corrections);
          break;
      }
      return;
    }

    yield checkingResult;
  }

  bool _checkFirstLetterMatches(String userInput) {
    return _firstChar.isEmpty || userInput.startsWith(_firstChar);
  }

  Future<WordCheckingResult> _checkInDatabase(String input) async {
    var word = input;
    var attempts = 2;

    do {
      var checkingResult = await _gameFacade.checkCity(input);
      if (checkingResult != null) {
        switch (checkingResult) {
          case CityResult.OK:
            return Accepted(input);
          case CityResult.CITY_NOT_FOUND:
            word = word.replaceAll(" ", "-");
            break;
          case CityResult.ALREADY_USED:
            return AlreadyUsed(input);
        }
      }
    } while (--attempts > 0);

    return NotFound(input);
  }
}
