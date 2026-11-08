import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';

void main() {
  // Short names cross the native social login channel ('networkType').
  const shortNames = {
    AuthType.native: 'nv',
    AuthType.google: 'gl',
    AuthType.vkontakte: 'vk',
    AuthType.odnoklassniki: 'ok',
    AuthType.facebook: 'fb',
  };

  // Full names are used by the game server and the REST API ('authType').
  const fullNames = {
    AuthType.native: 'Native',
    AuthType.google: 'Google',
    AuthType.vkontakte: 'Vkontakte',
    AuthType.odnoklassniki: 'Odnoklassniki',
    AuthType.facebook: 'Facebook',
  };

  group('short name', () {
    for (final MapEntry(key: type, value: wire) in shortNames.entries) {
      test('of $type is "$wire" both ways', () {
        // The short name is a field of its own: `type.name` is the
        // constant's Dart name and never goes over the channel.
        expect(type.shortName, wire);
        expect(AuthType.fromShortString(wire), type);
      });
    }

    test('parsing rejects a full name', () {
      expect(() => AuthType.fromShortString('Native'), throwsA(isA<String>()));
    });
  });

  group('full name', () {
    for (final MapEntry(key: type, value: wire) in fullNames.entries) {
      test('of $type is "$wire" both ways', () {
        expect(type.fullName, wire);
        expect(AuthType.fromString(wire), type);
      });
    }

    test('parsing rejects a short name', () {
      expect(() => AuthType.fromString('nv'), throwsA(isA<String>()));
    });
  });
}
