import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'voice_recognition_event.dart';

part 'voice_recognition_state.dart';

enum _ActionMode { start, stop }

/// BloC used to handle speech to text recognition
class VoiceRecognitionBloc
    extends Bloc<VoiceRecognitionEvent, VoiceRecognitionState>
    with SequentialEventMapping<VoiceRecognitionEvent, VoiceRecognitionState> {
  final VoiceRecognitionService _recognitionService;
  final void Function(String) _onWords;

  bool _autoStart = false;

  VoiceRecognitionBloc(this._onWords, this._recognitionService)
    : super(VoiceRecognitionInitial()) {
    mapEventsSequentially(_mapEventToState);
  }

  /// Also stops listening, so recognition does not outlive the game.
  @override
  Future<void> close() async {
    try {
      if (state is VoiceRecognitionListening) {
        await _recognitionService.cancel();
      }
    } finally {
      await super.close();
    }
  }

  Stream<VoiceRecognitionState> _mapEventToState(
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
        // The service may report the end of listening after close().
        if (!isClosed) add(VoiceRecognitionCancel());
      },
    );
    if (success) {
      yield VoiceRecognitionReady();
    } else {
      yield VoiceRecognitionUnavailable();
    }
  }

  Stream<VoiceRecognitionState> _toggleListening([_ActionMode? mode]) async* {
    // An automatic start while listening is not a request to stop.
    if (mode == _ActionMode.start && state is VoiceRecognitionListening) {
      return;
    }

    // _ActionMode.stop means stopped by service callback
    // So we should ignore it if
    if (state is VoiceRecognitionListening || mode == _ActionMode.stop) {
      final shouldStopAutostart = mode != _ActionMode.stop;

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
        if (!isClosed) _onWords(recognizedWords);
      });
    }
  }
}
