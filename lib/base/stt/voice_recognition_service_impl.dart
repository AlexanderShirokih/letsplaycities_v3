import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:speech_to_text/speech_recognition_result.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionServiceImpl implements VoiceRecognitionService {
  final stt.SpeechToText _speech;

  VoiceRecognitionServiceImpl() : _speech = stt.SpeechToText();

  stt.LocaleName? _selectedLocale;

  @override
  Future<bool> initialize({required void Function() onStop}) async {
    final isInitialized = await _speech.initialize(onStatus: (status) {
      if (status == 'notListening') {
        onStop();
      }

      print('On status: $status');
    }, onError: (error) {
      onStop();
      print('On error: $error');
    });

    if (!isInitialized) {
      return false;
    }

    var locales = await _speech.locales();

    try {
      _selectedLocale =
          locales.firstWhere((locale) => locale.localeId.contains('ru'));
    } on StateError {
      return false;
    }

    return true;
  }

  @override
  Future<void> listen(void Function(String recognizedWords) onResult) async {
    return _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      cancelOnError: true,
      partialResults: false,
      pauseFor: const Duration(seconds: 10),
      localeId: _selectedLocale!.localeId,
    );
  }

  @override
  Future<void> cancel() {
    return _speech.cancel();
  }
}
