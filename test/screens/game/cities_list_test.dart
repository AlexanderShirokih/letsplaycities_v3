import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as themes;
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

class _PassThroughChannel extends AbstractEventChannel {
  @override
  Stream<GameEvent> sendEvent(GameEvent event) => Stream.value(event);
}

/// A session whose events come from the test instead of the game loop.
class _FakeSession extends GameSession {
  final Stream<GameEvent> _events;

  _FakeSession(this._events, UsersList users)
    : super(
        mode: GameMode.playerVsPlayer,
        usersList: users,
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

  @override
  Stream<GameEvent> get inputEvents => _events;
}

const _theme = themes.Theme(
  name: 'test',
  primaryColor: Colors.blue,
  accentColor: Colors.red,
  fillColor: Colors.white,
  borderColor: Colors.black,
  messageMe: Colors.green,
  messageOther: Colors.grey,
);

void main() {
  late StreamController<GameEvent> events;
  late Player first;
  late Player second;
  late GameSessionRepository repository;
  late StateSetter setLayoutState;
  var listKey = 0;

  setUp(() {
    events = StreamController<GameEvent>.broadcast();
    first = Player(
      LocalAccountInfo(
        name: 'first',
        picture: const PlaceholderPictureSource(),
      ),
    );
    second = Player(
      LocalAccountInfo(
        name: 'second',
        picture: const PlaceholderPictureSource(),
      ),
    );
    repository = GameSessionRepository(
      _FakeSession(events.stream, UsersList([first, second])),
    );
    listKey = 0;
  });

  tearDown(() => events.close());

  // Builds a new CitiesList instance on every layout build, as the game
  // screen does.
  Widget app() => MaterialApp(
    home: RepositoryProvider<themes.Theme>.value(
      value: _theme,
      child: RepositoryProvider<GameSessionRepository>.value(
        value: repository,
        child: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setLayoutState = setState;
              return Column(children: [CitiesList(key: ValueKey(listKey))]);
            },
          ),
        ),
      ),
    ),
  );

  Future<void> play(WidgetTester tester, String city, User owner) async {
    events.add(Accepted(city, owner, status: CityStatus.waiting));
    await tester.pumpAndSettle();
  }

  testWidgets('keeps the played cities when the layout is rebuilt', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await play(tester, 'москва', first);
    await play(tester, 'анапа', second);
    expect(find.byType(GameItemListTile), findsNWidgets(2));

    setLayoutState(() {});
    await tester.pumpAndSettle();
    await play(tester, 'архангельск', first);

    expect(find.byType(GameItemListTile), findsNWidgets(3));
  });

  testWidgets('shows the played cities at once when the list is recreated', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await play(tester, 'москва', first);
    await play(tester, 'анапа', second);

    setLayoutState(() => listKey++);
    await tester.pumpAndSettle();
    expect(find.byType(GameItemListTile), findsNWidgets(2));

    await play(tester, 'архангельск', first);
    expect(find.byType(GameItemListTile), findsNWidgets(3));
  });
}
