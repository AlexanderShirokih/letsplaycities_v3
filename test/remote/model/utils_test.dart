import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

void main() {
  final remote = AppConfig.forHost('lps.test');

  group('getPictureUrlOrNull', () {
    test('builds the avatar URL with the picture hash', () {
      expect(
        getPictureUrlOrNull(remote, 42, 'abc123'),
        'https://lps.test:443/v1/avatars/42?v=abc123',
      );
    });

    test('uses the scheme and port of the LAN host', () {
      final lan = AppConfig.forHost('192.168.1.5', port: 8988, isSecure: false);

      expect(
        getPictureUrlOrNull(lan, 42, 'abc123'),
        'http://192.168.1.5:8988/v1/avatars/42?v=abc123',
      );
    });

    test('returns null without a picture hash', () {
      expect(getPictureUrlOrNull(remote, 42, null), isNull);
      expect(getPictureUrlOrNull(remote, 42, ''), isNull);
    });
  });

  test('getPictureUrlOrNullNoHash builds the avatar URL without a hash', () {
    expect(
      getPictureUrlOrNullNoHash(remote, '42'),
      'https://lps.test:443/v1/avatars/42',
    );
  });
}
