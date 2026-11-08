import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/handlers/event_processor.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';
import 'package:lets_play_cities/remote/remote_player.dart';

/// Sends the own words, chat messages and surrender to the server. A word
/// that the local checks accepted is accepted only by the verdict of the
/// server.
class NetworkInterceptor extends EventHandler {
  final RemoteGameClient _gameClient;

  /// The letter the current move has to start with, empty for any letter
  String _firstChar = '';

  NetworkInterceptor(this._gameClient);

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    if (event is OnFirstCharChanged) _firstChar = event.firstChar;

    if (event is Accepted && !_isTrusted(event.owner)) {
      final verdict = await _gameClient.sendWord(event.word);
      if (verdict == null) return;

      yield WordCheckingResult.of(
        _wordResultOf(verdict.status),
        event.owner,
        // The server normalises the word; its text is the word of record
        verdict.text,
        validLetter: _firstChar,
      );
    } else if (event is MessageEvent && !_isTrusted(event.owner)) {
      _gameClient.sendChat(event.message);
      yield event;
    } else if (event is LeaveRequested) {
      try {
        _gameClient.leave();
      } on RemoteIOException {
        // The server cannot hear the surrender: the game ends here
        yield OnMoveFinished(MoveFinishType.surrender, event.owner);
      }
    } else {
      // Pass any other events
      yield event;
    }
  }

  static WordResult _wordResultOf(WordStatus status) => switch (status) {
    WordStatus.accepted => WordResult.accepted,
    WordStatus.alreadyUsed => WordResult.already,
    WordStatus.unknown => WordResult.noWord,
    WordStatus.wrongLetter => WordResult.wrongLetter,
    WordStatus.notYourTurn => WordResult.wrongMove,
  };

  bool _isTrusted(User user) => user is RemotePlayer;
}
