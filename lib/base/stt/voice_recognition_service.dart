abstract class VoiceRecognitionService {
  const VoiceRecognitionService();

  Future<bool> initialize({required void Function() onStop});

  Future<void> listen(void Function(String recognizedWords) onResult);

  Future<void> cancel();
}
