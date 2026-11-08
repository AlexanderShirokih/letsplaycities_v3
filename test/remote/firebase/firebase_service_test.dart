import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/firebase/firebase_service.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

class _FakeMessaging extends Fake implements FirebaseMessaging {
  _FakeMessaging(this._token);

  final Future<String?> Function() _token;

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) => _token();
}

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) {}
}

void main() {
  late _RecordingLogger logger;

  setUp(() => logger = _RecordingLogger());

  test('an instance that is not configured yet has no token', () async {
    // Built from its logger alone, without a service locator
    final services = FirebaseServices(logger);

    await expectLater(
      services.getUserToken(),
      throwsA('Firebase messaging is not initialized!'),
    );
    expect(logger.errors, isEmpty);
  });

  test('getUserToken returns the FCM token', () async {
    final services = FirebaseServices.withMessaging(
      _FakeMessaging(() async => 'token'),
      logger,
    );

    expect(await services.getUserToken(), 'token');
  });

  test('getUserToken returns an empty token and logs the error when FCM '
      'is unavailable', () async {
    final unavailable = FirebaseException(
      plugin: 'firebase_messaging',
      code: 'SERVICE_NOT_AVAILABLE',
    );
    final services = FirebaseServices.withMessaging(
      _FakeMessaging(() => Future.error(unavailable)),
      logger,
    );

    expect(await services.getUserToken(), '');
    expect(logger.errors, [unavailable]);
  });

  group('push data', () {
    late FirebaseServices services;
    late List<IncomingCloudMessage> messages;

    setUp(() {
      services = FirebaseServices.withMessaging(
        _FakeMessaging(() async => 'token'),
        logger,
      );
      messages = [];
      services.messages.listen(messages.add);
    });

    test('an invite push becomes a game request', () async {
      services.handlePush({
        'type': 'invite',
        'fromId': '9',
        'fromName': 'Friend',
      });
      await pumpEventQueue();

      expect(messages, [const GameRequest(9, 'Friend')]);
    });

    test('other data is ignored', () async {
      services
        ..handlePush({'type': 'news'})
        ..handlePush({'action': 'fm_request', 'user_id': '9'})
        ..handlePush({});
      await pumpEventQueue();

      expect(messages, isEmpty);
    });
  });
}
