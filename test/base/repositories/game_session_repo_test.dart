import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

class _PassThroughChannel extends AbstractEventChannel {
  @override
  Stream<GameEvent> sendEvent(GameEvent event) => Stream.value(event);
}

GameSession _session() => GameSession(
  mode: GameMode.playerVsPlayer,
  usersList: UsersList([
    for (final name in ['first', 'second'])
      Player(
        LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
      ),
  ]),
  eventChannel: _PassThroughChannel(),
  scoringType: ScoringType.byScore,
  timeLimit: 0,
  scoreController: ScoreController(
    ScoringSet.initial(),
    ScoringType.byScore,
    GameMode.playerVsPlayer,
    (_) {},
  ),
  achievements: StubAchievementsService(),
  wordsDifficulty: () => Difficulty.easy,
);

/// Records what the repository delivers to the session and when.
class _RecordingSession extends Fake implements GameSession {
  final words = <String>[];
  final messages = <String>[];
  var cancelled = false;

  @override
  void deliverUserInput(String userInput) => words.add(userInput);

  @override
  void deliverUserMessage(String message) => messages.add(message);

  @override
  Future cancel() async => cancelled = true;
}

const _debounce = Duration(milliseconds: 1000);
const _ms = Duration(milliseconds: 1);

void main() {
  // The repository is created inside fakeAsync: its debouncers read the clock
  // on creation, and a call within one second of that is deferred.
  void inRepository(
    void Function(
      FakeAsync async,
      GameSessionRepository repository,
      _RecordingSession session,
    )
    body,
  ) {
    fakeAsync((async) {
      final session = _RecordingSession();
      final repository = GameSessionRepository(session);
      async.elapse(_debounce + _ms);
      body(async, repository, session);
    });
  }

  group('user input debounce', () {
    test('delivers a word at once, then defers the next one', () {
      inRepository((async, repository, session) {
        repository.sendInputWord('москва');
        expect(session.words, ['москва']);

        repository.sendInputWord('анапа');
        async.elapse(_debounce - _ms);
        expect(session.words, ['москва']);

        async.elapse(_ms);
        expect(session.words, ['москва', 'анапа']);
      });
    });

    test('a newer word replaces the deferred one', () {
      inRepository((async, repository, session) {
        repository.sendInputWord('москва');
        repository.sendInputWord('анапа');
        repository.sendInputWord('омск');

        async.elapse(_debounce);

        expect(session.words, ['москва', 'омск']);
      });
    });

    test('a chat message does not drop a deferred word', () {
      inRepository((async, repository, session) {
        repository.sendInputWord('москва');
        repository.sendInputWord('анапа');

        repository.sendChatMessage('привет');
        async.elapse(_debounce);

        expect(session.words, ['москва', 'анапа']);
        expect(session.messages, ['привет']);
      });
    });

    test('a word does not drop a deferred chat message', () {
      inRepository((async, repository, session) {
        repository.sendChatMessage('привет');
        repository.sendChatMessage('как дела');

        repository.sendInputWord('москва');
        async.elapse(_debounce);

        expect(session.messages, ['привет', 'как дела']);
        expect(session.words, ['москва']);
      });
    });

    test('a newer chat message replaces the deferred one', () {
      inRepository((async, repository, session) {
        repository.sendChatMessage('привет');
        repository.sendChatMessage('как дела');
        repository.sendChatMessage('пока');

        async.elapse(_debounce);

        expect(session.messages, ['привет', 'пока']);
      });
    });

    test('finishing the game drops deferred words and messages', () {
      inRepository((async, repository, session) {
        repository.sendInputWord('москва');
        repository.sendInputWord('анапа');
        repository.sendChatMessage('привет');
        repository.sendChatMessage('как дела');

        repository.finish();
        async.elapse(_debounce * 2);

        expect(session.cancelled, isTrue);
        expect(session.words, ['москва']);
        expect(session.messages, ['привет']);
      });
    });
  });

  test('keeps one game items repository per session', () {
    final repository = GameSessionRepository(_session());

    expect(
      identical(
        repository.createGameItemsRepository(),
        repository.createGameItemsRepository(),
      ),
      isTrue,
    );
    expect(
      identical(
        repository.gameItemsRepository,
        repository.createGameItemsRepository(),
      ),
      isTrue,
    );
  });
}
