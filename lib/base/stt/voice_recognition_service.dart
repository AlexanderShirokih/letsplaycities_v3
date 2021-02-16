abstract class VoiceRecognitionService {
  const VoiceRecognitionService();

  Future<bool> initialize({required void Function() onStop});

  Future<void> listen(void Function(String recognizedWords) onResult);

  Future<void> cancel();
}

/// Stub implementation used in debugging purposes on desktop
class StubVoiceRecognitionService implements VoiceRecognitionService {
  @override
  Future<void> cancel() {
    return Future.value();
  }

  @override
  Future<bool> initialize({required void Function() onStop}) async {
    return false;
  }

  @override
  Future<void> listen(void Function(String recognizedWords) onResult) {
    return Future.value();
  }
}
