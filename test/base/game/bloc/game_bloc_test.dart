import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/exclusion_messages.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/dictionary_updater.dart';

import '../../dictionary/impl/dictionary_test_files.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  String scoringData = '';

  @override
  ScoringType scoringType = ScoringType.byScore;

  @override
  int timeLimit = 0;

  @override
  Difficulty wordsDifficulty = Difficulty.easy;
}

class _FakeExclusionMessages extends Fake implements ExclusionMessages {}

class _NoOverrides implements CountryCodeOverrides {
  @override
  int? findOverride(String word) => null;
}

class _RecordingAchievements extends Fake implements AchievementsService {
  final unlocked = <Achievement>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => unlocked.add(achievement);

  @override
  Future<void> submitScore(int score) async {}
}

class _FakeDictionaryUpdater extends Fake implements DictionaryUpdater {
  final List<int> progress;
  var checks = 0;

  /// Fails after [progress] with an error that is not a `RemoteException`.
  final Object? failure;

  _FakeDictionaryUpdater([this.progress = const [], this.failure]);

  @override
  Stream<int> checkForUpdates() {
    checks++;
    return Stream.fromIterable(progress)
        .concatWith([if (failure != null) Stream<int>.error(failure!)]);
  }
}

/// Fails its first move, and fails again when the game closes it.
class _BrokenUser extends User {
  _BrokenUser()
    : super(
        accountInfo: const LocalAccountInfo(
          name: 'broken',
          picture: PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: false,
      );

  @override
  Future<String> onCreateWord(String firstChar) =>
      Future.error(StateError('broken move'));

  @override
  Future<void> close() => Future.error(StateError('broken close'));
}

Player _player(String name) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

/// Alternates turns of the real event loop with fake-time pumps until
/// [condition] holds. The dictionary loading reads a file, and the bloc work
/// that follows a real read needs real turns as well.
Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  final elapsed = Stopwatch()..start();
  while (!condition() && elapsed.elapsed < const Duration(seconds: 5)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump();
  }
  expect(condition(), isTrue);
}

void main() {
  late Directory supportDir;
  late _FakePreferences prefs;
  late _RecordingAchievements achievements;
  late _FakeDictionaryUpdater updater;
  late List<GameLifecycleState> states;
  late GameBloc bloc;

  void startBloc(GameConfig config) {
    bloc = GameBloc(
      gameConfig: config,
      prefs: prefs,
      exclusionMessages: _FakeExclusionMessages(),
      playerNames: const DefaultPlayerNames(
        player: 'player',
        android: 'android',
        firstPlayer: 'first',
        secondPlayer: 'second',
      ),
      codeOverrides: _NoOverrides(),
      dictionaryUpdater: updater,
      achievements: achievements,
    );
    bloc.stream.listen(states.add);
  }

  /// Closes the bloc and lets the game loop see that it was cancelled.
  Future<void> closeBloc(WidgetTester tester) async {
    var closed = false;
    unawaited(bloc.close().then((_) => closed = true));
    await _pumpUntil(tester, () => closed);
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Lets the first player of a game on one device make the move the game
  /// waits for.
  Future<void> openGate(WidgetTester tester) async {
    // Fake time covers the start delay of the game loop.
    await tester.pump(const Duration(milliseconds: 200));
    await _pumpUntil(tester, () => bloc.turnGate!.waiting.value != null);
    bloc.turnGate!.release();
  }

  setUp(() {
    supportDir = Directory.systemTemp.createTempSync('game_bloc');
    fakeApplicationSupportDirectory(supportDir);
    prefs = _FakePreferences();
    achievements = _RecordingAchievements();
    updater = _FakeDictionaryUpdater();
    states = [];
  });

  tearDown(() {
    // The cached asset futures belong to the fake-time zone of this test and
    // would never complete in the next one.
    rootBundle.clear();
    DictionaryFactory.invalidateCache();
    fakeApplicationSupportDirectory(null);
    supportDir.deleteSync(recursive: true);
  });

  testWidgets('a local game shows the progress of the dictionary update', (
    tester,
  ) async {
    updater = _FakeDictionaryUpdater([-1, 0, 100]);
    startBloc(const GameConfig(gameMode: GameMode.playerVsPlayer));

    await _pumpUntil(tester, () => bloc.state is GameState);

    expect(updater.checks, 1);
    expect(states.take(4), [
      const CheckingForUpdatesState(CheckingForUpdatesStage.fetchingUpdate, -1),
      const CheckingForUpdatesState(CheckingForUpdatesStage.updating, 0),
      const CheckingForUpdatesState(CheckingForUpdatesStage.updating, 100),
      const DataLoadingState(),
    ]);
    await closeBloc(tester);
  });

  testWidgets('a failed dictionary update does not stop a local game', (
    tester,
  ) async {
    updater = _FakeDictionaryUpdater([-1], StateError('unexpected response'));
    startBloc(const GameConfig(gameMode: GameMode.playerVsPlayer));

    await _pumpUntil(tester, () => bloc.state is GameState);

    expect(states.whereType<ErrorState>(), isEmpty);
    await closeBloc(tester);
  });

  testWidgets('only a game on one device waits at the turn gate', (
    tester,
  ) async {
    startBloc(const GameConfig(gameMode: GameMode.playerVsAndroid));
    await _pumpUntil(tester, () => bloc.state is GameState);

    expect(bloc.turnGate, isNull);
    await closeBloc(tester);
  });

  testWidgets('leaving game while gate is closed emits no error', (
    tester,
  ) async {
    startBloc(const GameConfig(gameMode: GameMode.playerVsPlayer));
    await _pumpUntil(tester, () => bloc.state is GameState);
    // Fake time covers the start delay of the game loop.
    await tester.pump(const Duration(milliseconds: 200));
    await _pumpUntil(tester, () => bloc.turnGate!.waiting.value != null);

    await closeBloc(tester);

    expect(bloc.turnGate!.waiting.value, isNull);
    expect(states.whereType<ErrorState>(), isEmpty);
  });

  testWidgets('a network game does not check for dictionary updates', (
    tester,
  ) async {
    startBloc(
      GameConfig(
        gameMode: GameMode.network,
        usersListOverride: UsersList([_player('first'), _player('second')]),
      ),
    );

    await _pumpUntil(tester, () => bloc.state is GameState);

    expect(updater.checks, 0);
    expect(states.first, const DataLoadingState());
    await closeBloc(tester);
  });

  testWidgets('a hint is given at once and unlocks use3Tips progress', (
    tester,
  ) async {
    startBloc(const GameConfig(gameMode: GameMode.playerVsAndroid));
    await _pumpUntil(tester, () => bloc.state is GameState);
    states.clear();

    bloc.add(const GameEventShowHelp());
    await _pumpUntil(tester, () => achievements.unlocked.length == 2);

    expect(achievements.unlocked, [
      Achievement.use3Tips,
      Achievement.use30Tips,
    ]);
    expect(states, isEmpty);
    await closeBloc(tester);
  });

  testWidgets('the next hint comes in two minutes', (tester) async {
    startBloc(const GameConfig(gameMode: GameMode.playerVsAndroid));
    await _pumpUntil(tester, () => bloc.state is GameState);
    final hintReadyAt =
        (bloc.state as GameState).gameSessionRepository.hintReadyAt;
    expect(hintReadyAt.value, isNull);

    bloc.add(const GameEventShowHelp());
    await _pumpUntil(tester, () => achievements.unlocked.length == 2);

    final readyAt = hintReadyAt.value!;
    final wait = readyAt.difference(clock.now()).inSeconds;
    expect(wait, inInclusiveRange(GameBloc.hintCooldown.inSeconds - 1, 120));

    // A second hint before then is ignored
    bloc.add(const GameEventShowHelp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(achievements.unlocked, hasLength(2));
    expect(hintReadyAt.value, readyAt);
    await closeBloc(tester);
  });

  testWidgets('a finished game reports achievements with the difficulty set '
      'at its end', (tester) async {
    final player = _player('player')..increaseScore(10);
    startBloc(
      GameConfig(
        gameMode: GameMode.playerVsPlayer,
        usersListOverride: UsersList([player, _player('second')]),
      ),
    );
    await _pumpUntil(tester, () => bloc.state is GameState);
    await openGate(tester);

    prefs.wordsDifficulty = Difficulty.hard;
    bloc.add(const GameEventSurrender());
    await _pumpUntil(tester, () => bloc.state is GameResultsState);

    expect(achievements.unlocked, contains(Achievement.playInHardMode));
    await closeBloc(tester);
  });

  testWidgets('a failed game shows its own error when the cleanup fails too', (
    tester,
  ) async {
    final printed = <String?>[];
    final savedDebugPrint = debugPrint;
    // Restored in the test body: the binding checks it before tearDown.
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    try {
      startBloc(
        GameConfig(
          gameMode: GameMode.playerVsPlayer,
          usersListOverride: UsersList([_BrokenUser(), _player('player')]),
        ),
      );
      await _pumpUntil(tester, () => bloc.state is GameState);
      await openGate(tester);
      await _pumpUntil(tester, () => bloc.state is ErrorState);

      final error = (bloc.state as ErrorState).exception;
      expect(error, isA<StateError>());
      expect((error as StateError).message, 'broken move');
      expect(printed.single, contains('broken close'));
      await closeBloc(tester);
    } finally {
      debugPrint = savedDebugPrint;
    }
  });
}
