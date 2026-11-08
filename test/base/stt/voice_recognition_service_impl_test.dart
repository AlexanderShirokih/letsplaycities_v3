import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service_impl.dart';

const _channel = MethodChannel('plugin.csdcorp.com/speech_to_text');

/// A recognition result as the platform side of the plugin encodes it.
String _result(String words, {required int resultType}) => jsonEncode({
  'alternates': [
    {'recognizedWords': words, 'confidence': 0.9},
  ],
  'resultType': resultType,
});

/// Delivers [method] from the platform side of the speech_to_text plugin.
Future<void> _fromPlatform(String method, Object arguments) =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          _channel.name,
          _channel.codec.encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Calls the plugin made to the platform side in the current test.
  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          platformCalls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'locales' => ['ru_RU:Русский'],
            'listen' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('the end of listening reaches the latest initialize caller', () async {
    final service = VoiceRecognitionServiceImpl();
    var firstStops = 0;
    var latestStops = 0;

    expect(await service.initialize(onStop: () => firstStops++), isTrue);
    expect(await service.initialize(onStop: () => latestStops++), isTrue);
    await _fromPlatform('notifyStatus', 'notListening');

    expect(firstStops, 0);
    expect(latestStops, 1);
  });

  test('a recognition error reaches the latest initialize caller', () async {
    final service = VoiceRecognitionServiceImpl();
    var firstStops = 0;
    var latestStops = 0;

    await service.initialize(onStop: () => firstStops++);
    await service.initialize(onStop: () => latestStops++);
    await _fromPlatform(
      'notifyError',
      '{"errorMsg": "error_no_match", "permanent": true}',
    );

    expect(firstStops, 0);
    expect(latestStops, 1);
  });

  test('listen sends the session options to the platform', () async {
    final service = VoiceRecognitionServiceImpl();
    await service.initialize(onStop: () {});

    await service.listen((_) {});
    addTearDown(service.cancel);

    final listen = platformCalls.singleWhere((c) => c.method == 'listen');
    expect(listen.arguments, {
      // A pause timeout needs partial results to see that speech goes on.
      'partialResults': true,
      'onDevice': false,
      'listenMode': 3, // ListenMode.confirmation
      'sampleRate': 0,
      'enableHaptics': false,
      'autoPunctuation': false,
      'pauseFor': 10000,
      'listenFor': null,
      'localeId': 'ru_RU',
    });
  });

  test('only the final result reaches the listener', () async {
    final service = VoiceRecognitionServiceImpl();
    final heard = <String>[];
    await service.initialize(onStop: () {});

    await service.listen(heard.add);
    addTearDown(service.cancel);
    await _fromPlatform('textRecognition', _result('мос', resultType: 0));
    await _fromPlatform('textRecognition', _result('моск', resultType: 1));
    await _fromPlatform('textRecognition', _result('москва', resultType: 2));

    expect(heard, ['москва']);
  });
}
