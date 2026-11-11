import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';
import 'package:lets_play_cities/remote/social/social_network_data.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The native side of social login listens on this channel and reads the
  // network from the short 'authType' name.
  const channel = MethodChannel('ru.aleshi.letsplaycities/authentication');

  const shortNames = {
    AuthType.native: 'nv',
    AuthType.google: 'gl',
    AuthType.vkontakte: 'vk',
    AuthType.odnoklassniki: 'ok',
  };

  late List<MethodCall> calls;

  void answerWith(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(() => calls = []);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  final service = NativeBridgeSocialNetworksService();

  for (final MapEntry(key: type, value: wire) in shortNames.entries) {
    test('login with $type sends authType "$wire" and reads the result '
        'back', () async {
      answerWith(
        (call) => {
          'login': 'Alice',
          'networkType': (call.arguments as Map)['authType'],
          'pictureUri': 'https://pictures.test/alice.png',
          'accessToken': 'sn-token',
          'snUID': 'sn-42',
        },
      );

      final data = await service.login(type);

      expect(calls.single.method, 'login');
      expect(calls.single.arguments, {'authType': wire});
      expect(
        data,
        SocialNetworkData(
          login: 'Alice',
          authType: type,
          pictureUri: 'https://pictures.test/alice.png',
          accessToken: 'sn-token',
          snUID: 'sn-42',
        ),
      );
    });

    test('logout from $type sends authType "$wire"', () async {
      answerWith((_) => null);

      await service.logout(type);

      expect(calls.single.method, 'logout');
      expect(calls.single.arguments, {'authType': wire});
    });
  }

  test('login reads the short networkType "vk" as Vkontakte', () async {
    answerWith(
      (_) => {
        'login': 'Bob',
        'networkType': 'vk',
        'pictureUri': '',
        'accessToken': 'vk-token',
        'snUID': '7',
      },
    );

    final data = await service.login(AuthType.vkontakte);

    expect(data.authType, AuthType.vkontakte);
  });

  test('login turns a native error into an AuthorizationException', () async {
    answerWith(
      (_) => throw PlatformException(code: 'cancelled', message: 'by user'),
    );

    await expectLater(
      service.login(AuthType.google),
      throwsA(
        isA<AuthorizationException>().having(
          (e) => e.description,
          'description',
          'cancelled: by user',
        ),
      ),
    );
  });

  group('getDeviceId', () {
    test('returns the native device ID', () async {
      answerWith((_) => 'android-id-1');

      expect(
        await NativeBridgeSocialNetworksService(isLinux: false).getDeviceId(),
        'android-id-1',
      );
      expect(calls.single.method, 'getDeviceId');
    });

    test('rethrows a native error on a phone instead of a shared ID', () async {
      answerWith((_) => throw PlatformException(code: 'no-activity'));

      await expectLater(
        NativeBridgeSocialNetworksService(isLinux: false).getDeviceId(),
        throwsA(isA<PlatformException>()),
      );
    });

    test(
      'falls back to the test ID on Linux, which has no native side',
      () async {
        // No handler: the channel throws MissingPluginException.
        expect(
          await NativeBridgeSocialNetworksService(isLinux: true).getDeviceId(),
          'linuz-test',
        );

        answerWith((_) => throw PlatformException(code: 'error'));
        expect(
          await NativeBridgeSocialNetworksService(isLinux: true).getDeviceId(),
          'linuz-test',
        );
      },
    );
  });
}
