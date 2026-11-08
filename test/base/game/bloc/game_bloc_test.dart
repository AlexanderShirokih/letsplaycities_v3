import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
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

class _FakeAdManager extends Fake implements AdManager {
  var setUps = 0;
  var rewardedReady = false;

  @override
  void setUpAds(OnRewardedAdShown onAdShown) => setUps++;

  @override
  Future<bool> showRewarded() async => rewardedReady;
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

  _FakeDictionaryUpdater([this.progress = const []]);

  @override
  Stream<int> checkForUpdates() {
    checks++;
    return Stream.fromIterable(progress);
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
  late _FakeAdManager adManager;
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
      adManager: adManager,
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

  setUp(() {
    supportDir = Directory.systemTemp.createTempSync('game_bloc');
    fakeApplicationSupportDirectory(supportDir);
    prefs = _FakePreferences();
    adManager = _FakeAdManager();
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
    expect(adManager.setUps, 1);
    expect(states.take(4), [
      const CheckingForUpdatesState(CheckingForUpdatesStage.fetchingUpdate, -1),
      const CheckingForUpdatesState(CheckingForUpdatesStage.updating, 0),
      const CheckingForUpdatesState(CheckingForUpdatesStage.updating, 100),
      const DataLoadingState(),
    ]);
    await closeBloc(tester);
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

  testWidgets('help that is not ready yet is reported and the game goes on', (
    tester,
  ) async {
    startBloc(const GameConfig(gameMode: GameMode.playerVsAndroid));
    await _pumpUntil(tester, () => bloc.state is GameState);
    final gameState = bloc.state;
    states.clear();

    bloc.add(const GameEventShowHelp());
    await _pumpUntil(tester, () => states.length == 2);

    expect(states, [
      const GameNotificationState(GameNotification.hintNotReady),
      gameState,
    ]);
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
    // Fake time covers the start delay of the game loop.
    await tester.pump(const Duration(milliseconds: 200));

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
      // Fake time covers the start delay of the game loop.
      await tester.pump(const Duration(milliseconds: 200));
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
