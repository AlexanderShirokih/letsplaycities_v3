import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';

void main() {
  group('GameRequest.tryParse', () {
    // FCM delivers every data value as a string.
    const data = {'type': 'invite', 'fromId': '9', 'fromName': 'Friend'};

    test('invite push parses fromId/fromName', () {
      expect(GameRequest.tryParse(data), const GameRequest(9, 'Friend'));
    });

    test('non-invite data is ignored', () {
      expect(GameRequest.tryParse({...data, 'type': 'news'}), isNull);
      expect(GameRequest.tryParse({'action': 'fm_request'}), isNull);
    });

    test('an invite without a numeric sender is ignored', () {
      expect(GameRequest.tryParse({...data, 'fromId': 'nine'}), isNull);
      expect(GameRequest.tryParse({'type': 'invite', 'fromName': 'A'}), isNull);
      expect(GameRequest.tryParse({'type': 'invite', 'fromId': '9'}), isNull);
    });
  });
}
