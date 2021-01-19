import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

class BackJsonMessageConverter
    extends MessageConverter<ClientMessage, ServerMessage> {
  @override
  ClientMessage decode(String data) {
    // TODO: implement decode
    throw UnimplementedError();
  }

  @override
  String encode(ServerMessage message) {
    // TODO: implement encode
    throw UnimplementedError();
  }
}
