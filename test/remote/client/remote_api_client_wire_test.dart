import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth.dart';

void main() {
  group('RemoteSignUpResponse', () {
    // The sign-up response stores the role as 'state' with the server's
    // names; Role.regular is 'ready' there.
    const states = {
      Role.banned: 'banned',
      Role.regular: 'ready',
      Role.admin: 'admin',
    };

    for (final MapEntry(key: role, value: state) in states.entries) {
      test('writes and reads $role as state "$state"', () {
        final response = RemoteSignUpResponse(
          userId: 42,
          login: 'Alice',
          accessToken: 'acc',
          pictureHash: 'pic',
          role: role,
          authType: AuthType.vkontakte,
        );

        final map = response.toMap();
        final read = RemoteSignUpResponse.fromMap(map);

        expect(map, {
          'userId': 42,
          'name': 'Alice',
          'accHash': 'acc',
          'picHash': 'pic',
          'state': state,
          'authType': 'Vkontakte',
        });
        expect(read.role, role);
        expect(read.authType, AuthType.vkontakte);
      });
    }

    test('reading an unknown state throws', () {
      expect(
        () => RemoteSignUpResponse.fromMap({
          'userId': 42,
          'name': 'Alice',
          'accHash': 'acc',
          'picHash': 'pic',
          'state': 'regular',
          'authType': 'Native',
        }),
        throwsA(isA<String>()),
      );
    });
  });
}
