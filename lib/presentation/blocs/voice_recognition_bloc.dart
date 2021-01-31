import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';

part 'voice_recognition_event.dart';
part 'voice_recognition_state.dart';

enum _ActionMode { start, stop }

/// BloC used to handle speech to text recognition
class VoiceRecognitionBloc
    extends Bloc<VoiceRecognitionEvent, VoiceRecognitionState> {
  final VoiceRecognitionService _recognitionService;
  final void Function(String) _onWords;

  bool _autoStart = false;

  VoiceRecognitionBloc(this._onWords)
      : _recognitionService = GetIt.instance.get<VoiceRecognitionService>(),
        super(VoiceRecognitionInitial());

  @override
  Stream<VoiceRecognitionState> mapEventToState(
    VoiceRecognitionEvent event,
  ) async* {
    if (event is VoiceRecognitionCancel) {
      yield* _toggleListening(_ActionMode.stop);
    } else if (event is VoiceRecognitionAutoBegin) {
      yield* _toggleListening(_ActionMode.start);
    } else if (event is VoiceRecognitionInit) {
      yield* _initRecognition();
    } else if (event is VoiceRecognitionToggle) {
      yield* _toggleListening();
    }
  }

  Stream<VoiceRecognitionState> _initRecognition() async* {
    final success = await _recognitionService.initialize(
      onStop: () {
        add(VoiceRecognitionCancel());
      },
    );
    if (success) {
      yield VoiceRecognitionReady();
    } else {
      yield VoiceRecognitionUnavailable();
    }
  }

  Stream<VoiceRecognitionState> _toggleListening([_ActionMode? mode]) async* {
    // _ActionMode.stop means stopped by service callback
    // So we should ignore it if
    if (state is VoiceRecognitionListening || mode == _ActionMode.stop) {
      final shouldStopAutostart = mode != _ActionMode.stop;

      print("shouldStop=${shouldStopAutostart}");

      if (shouldStopAutostart) {
        _autoStart = false;
        // Stops listening
        await _recognitionService.cancel();
      }

      yield VoiceRecognitionReady();
    } else {
      /// 'true' if it's system automatic event
      /// 'false' means manual user click
      final autostartRequested = mode == _ActionMode.start;
      if (autostartRequested) {
        if (!_autoStart) {
          return;
        }
      } else {
        _autoStart = true;
      }

      // Starts listening
      yield VoiceRecognitionListening();
      await _recognitionService.listen((recognizedWords) {
        _onWords(recognizedWords);
      });
    }
  }
}
