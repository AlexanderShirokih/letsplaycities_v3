import 'package:lets_play_cities/base/game/handlers/event_processor.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/remote_player.dart';

/// Intercepts [Accepted] words, sends them to the server and handles result.
class NetworkInterceptor extends EventHandler {
  final RemoteGameClient _gameClient;

  NetworkInterceptor(this._gameClient) : assert(_gameClient != null);

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    if (event is Accepted && !_isTrusted(event.owner)) {
      final result = await _gameClient
          .sendWord(event.owner.accountInfo, event.word)
          .then((res) => WordCheckingResult.of(res, event.owner, event.word));

      yield result;
    } else if (event is MessageEvent && !_isTrusted(event.owner)) {
      await _gameClient.sendChatMessage(event.message);
      yield event;
    } else {
      // Pass any other events
      yield event;
    }
  }

  bool _isTrusted(User user) => user is RemotePlayer;
}
