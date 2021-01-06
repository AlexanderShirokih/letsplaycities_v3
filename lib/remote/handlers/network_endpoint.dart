import 'package:lets_play_cities/base/game/handlers/event_processor.dart';
import 'package:lets_play_cities/base/game/management/game_events.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';

/// Intercepts [Accepted] words, sends them to the server and handles result.
class NetworkEndpoint extends EventHandler {
  final RemoteGameClient _gameClient;

  NetworkEndpoint(this._gameClient) : assert(_gameClient != null);

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    // TODO: implement process
    yield event;
  }
}
