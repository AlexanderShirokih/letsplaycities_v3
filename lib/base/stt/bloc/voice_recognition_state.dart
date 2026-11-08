part of 'voice_recognition_bloc.dart';

abstract class VoiceRecognitionState extends Equatable {
  const VoiceRecognitionState();
}

class VoiceRecognitionInitial extends VoiceRecognitionState {
  @override
  List<Object> get props => [];
}

class VoiceRecognitionReady extends VoiceRecognitionState {
  @override
  List<Object> get props => [];
}

class VoiceRecognitionUnavailable extends VoiceRecognitionState {
  @override
  List<Object> get props => [];
}

class VoiceRecognitionListening extends VoiceRecognitionState {
  @override
  List<Object?> get props => [];
}
