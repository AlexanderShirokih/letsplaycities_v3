import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';

void main() {
  test('AppConfig builds v1 urls', () {
    final config = AppConfig.forHost('lps.test');

    expect(config.restBaseUrl, 'https://lps.test:443/v1');
    expect(config.gameSocketUrl, 'wss://lps.test:443/v1/game');
    expect(config.pinCertificate, isFalse);
  });

  test('a plain server uses http and ws', () {
    final config = AppConfig.forHost('lps.test', port: 8080, isSecure: false);

    expect(config.restBaseUrl, 'http://lps.test:8080/v1');
    expect(config.gameSocketUrl, 'ws://lps.test:8080/v1/game');
  });

  test('a LAN server is plain, not pinned and on port 8988', () {
    final config = AppConfig.lan('192.168.1.5');

    expect(config.isSecure, isFalse);
    expect(config.pinCertificate, isFalse);
    expect(config.port, 8988);
    expect(config.gameSocketUrl, 'ws://192.168.1.5:8988/v1/game');
  });

  test('environment without LPS_HOST fails fast', () {
    // The tests run without --dart-define.
    expect(
      AppConfig.fromEnvironment,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('LPS_HOST'),
        ),
      ),
    );
  });
}
