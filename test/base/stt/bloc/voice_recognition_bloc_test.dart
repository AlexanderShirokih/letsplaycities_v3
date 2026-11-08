import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';

class _FakeVoiceRecognitionService implements VoiceRecognitionService {
  _FakeVoiceRecognitionService({this.available = true, this.initError});

  final bool available;

  /// Thrown by [initialize] while set.
  Object? initError;

  void Function()? onStop;
  void Function(String recognizedWords)? onResult;
  int listens = 0;
  int cancels = 0;

  @override
  Future<bool> initialize({required void Function() onStop}) async {
    this.onStop = onStop;
    final error = initError;
    if (error != null) throw error;
    return available;
  }

  @override
  Future<void> listen(void Function(String recognizedWords) onResult) async {
    listens++;
    this.onResult = onResult;
  }

  @override
  Future<void> cancel() async => cancels++;
}

class _ErrorRecordingObserver extends BlocObserver {
  final errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  late _FakeVoiceRecognitionService service;
  late List<String> words;
  late VoiceRecognitionBloc bloc;

  Future<void> createInitializedBloc(
    _FakeVoiceRecognitionService fakeService,
  ) async {
    service = fakeService;
    words = [];
    bloc = VoiceRecognitionBloc(words.add, service)
      ..add(VoiceRecognitionInit());
    await pumpEventQueue();
  }

  tearDown(() => bloc.close());

  group('with an available service', () {
    setUp(() => createInitializedBloc(_FakeVoiceRecognitionService()));

    Future<void> startListening() async {
      bloc.add(VoiceRecognitionToggle());
      await pumpEventQueue();
      expect(bloc.state, isA<VoiceRecognitionListening>());
    }

    test('initialization makes recognition ready', () {
      expect(bloc.state, isA<VoiceRecognitionReady>());
      expect(service.onStop, isNotNull);
    });

    test('recognized words reach onWords', () async {
      await startListening();

      service.onResult!('москва');

      expect(words, ['москва']);
    });

    test('a manual toggle while listening stops recognition', () async {
      await startListening();

      bloc.add(VoiceRecognitionToggle());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceRecognitionReady>());
      expect(service.cancels, 1);
    });

    test(
      'the end of listening reported by the service needs no cancel',
      () async {
        await startListening();

        service.onStop!();
        await pumpEventQueue();

        expect(bloc.state, isA<VoiceRecognitionReady>());
        expect(service.cancels, 0);
      },
    );

    test(
      'an automatic start before any manual start does not listen',
      () async {
        bloc.add(VoiceRecognitionAutoBegin());
        await pumpEventQueue();

        expect(bloc.state, isA<VoiceRecognitionReady>());
        expect(service.listens, 0);
      },
    );

    test('a manual stop turns auto-listening off', () async {
      await startListening();
      bloc.add(VoiceRecognitionToggle());
      await pumpEventQueue();

      bloc.add(VoiceRecognitionAutoBegin());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceRecognitionReady>());
      expect(service.listens, 1);
    });

    test('an automatic start while listening keeps listening', () async {
      await startListening();

      bloc.add(VoiceRecognitionAutoBegin());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceRecognitionListening>());
      expect(service.cancels, 0);

      // Auto-listening stays on for the next move.
      service.onStop!();
      await pumpEventQueue();
      bloc.add(VoiceRecognitionAutoBegin());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceRecognitionListening>());
      expect(service.listens, 2);
    });

    test('closing while listening stops recognition', () async {
      await startListening();

      await bloc.close();

      expect(service.cancels, 1);
    });

    test('the end of listening reported after close is ignored', () async {
      await bloc.close();

      expect(() => service.onStop!(), returnsNormally);
    });

    test('words recognized after close are dropped', () async {
      await startListening();
      await bloc.close();

      service.onResult!('москва');

      expect(words, isEmpty);
    });
  });

  test('an unavailable service makes recognition unavailable', () async {
    await createInitializedBloc(_FakeVoiceRecognitionService(available: false));

    expect(bloc.state, isA<VoiceRecognitionUnavailable>());
    expect(service.listens, 0);
  });

  group('when initialization throws', () {
    late BlocObserver previousObserver;
    late _ErrorRecordingObserver observer;

    setUp(() {
      previousObserver = Bloc.observer;
      observer = _ErrorRecordingObserver();
      Bloc.observer = observer;
    });

    tearDown(() => Bloc.observer = previousObserver);

    test('the error is reported and the bloc keeps handling events', () async {
      final error = StateError('speech engine is missing');
      await createInitializedBloc(
        _FakeVoiceRecognitionService(initError: error),
      );

      expect(observer.errors, [error]);
      expect(bloc.state, isA<VoiceRecognitionInitial>());

      service.initError = null;
      bloc.add(VoiceRecognitionInit());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceRecognitionReady>());
    });
  });
}
