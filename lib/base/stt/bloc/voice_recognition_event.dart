part of 'voice_recognition_bloc.dart';

abstract class VoiceRecognitionEvent extends Equatable {
  const VoiceRecognitionEvent();
}

class VoiceRecognitionInit extends VoiceRecognitionEvent {
  @override
  List<Object?> get props => [];
}

class VoiceRecognitionToggle extends VoiceRecognitionEvent {
  @override
  List<Object?> get props => [];
}

class VoiceRecognitionAutoBegin extends VoiceRecognitionEvent {
  @override
  List<Object?> get props => [];
}

class VoiceRecognitionCancel extends VoiceRecognitionEvent {
  @override
  List<Object?> get props => [];
}
