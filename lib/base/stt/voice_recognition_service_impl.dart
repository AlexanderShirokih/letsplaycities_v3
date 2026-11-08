import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';

import 'package:speech_to_text/speech_recognition_error.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:speech_to_text/speech_recognition_result.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionServiceImpl implements VoiceRecognitionService {
  final stt.SpeechToText _speech;

  VoiceRecognitionServiceImpl() : _speech = stt.SpeechToText();

  stt.LocaleName? _selectedLocale;

  /// The stop callback of the latest [initialize] call.
  void Function()? _onStop;

  @override
  Future<bool> initialize({required void Function() onStop}) async {
    // SpeechToText is a process-wide singleton whose initialize() keeps the
    // listeners of its first successful call, so they are rebound here and
    // forward to the latest caller.
    _onStop = onStop;
    _speech
      ..statusListener = _onStatus
      ..errorListener = _onError;

    final isInitialized = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );

    if (!isInitialized) {
      return false;
    }

    var locales = await _speech.locales();

    try {
      _selectedLocale = locales.firstWhere(
        (locale) => locale.localeId.contains('ru'),
      );
    } on StateError {
      return false;
    }

    return true;
  }

  void _onStatus(String status) {
    if (status == 'notListening') {
      _onStop?.call();
    }

    debugPrint('On status: $status');
  }

  void _onError(SpeechRecognitionError error) {
    _onStop?.call();
    debugPrint('On error: $error');
  }

  @override
  Future<void> listen(void Function(String recognizedWords) onResult) async {
    return _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        // With listenOptions the plugin also forwards partial results.
        if (!result.finalResult) return;
        onResult(result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        // The pause timeout needs partial results to see that speech goes
        // on, so the platform gets them even though only the final one is
        // used.
        partialResults: true,
        pauseFor: const Duration(seconds: 10),
        localeId: _selectedLocale!.localeId,
      ),
    );
  }

  @override
  Future<void> cancel() {
    return _speech.cancel();
  }
}
