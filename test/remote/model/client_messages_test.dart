import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';

void main() {
  // The converter tests compare decoded messages with ==, which proves the
  // text only while equality includes it.
  test('outgoing messages are equal only with the same text', () {
    expect(
      const OutgoingWordMessage(word: 'москва'),
      const OutgoingWordMessage(word: 'москва'),
    );
    expect(
      const OutgoingWordMessage(word: 'москва'),
      isNot(const OutgoingWordMessage(word: 'анапа')),
    );
    expect(
      const OutgoingChatMessage(msg: 'Привет!'),
      const OutgoingChatMessage(msg: 'Привет!'),
    );
    expect(
      const OutgoingChatMessage(msg: 'Привет!'),
      isNot(const OutgoingChatMessage(msg: 'Пока!')),
    );
  });
}
