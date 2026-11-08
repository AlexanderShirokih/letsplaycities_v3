import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

void main() {
  group('GameRequest.fromMap', () {
    // FCM delivers every data value as a string.
    const data = {
      'action': 'fm_request',
      'login': 'Friend',
      'user_id': '9',
      'target_id': '42',
    };

    test('reads the sender and the target from a push payload', () {
      expect(GameRequest.fromMap(data), const GameRequest('Friend', 9, 42));
    });

    test('exposes the sender as the requester without a picture', () {
      expect(
        GameRequest.fromMap(data).requester,
        const BaseProfileInfo(userId: 9, login: 'Friend'),
      );
    });

    test('rejects a non-numeric user ID', () {
      expect(
        () => GameRequest.fromMap({...data, 'user_id': 'nine'}),
        throwsFormatException,
      );
    });
  });
}
