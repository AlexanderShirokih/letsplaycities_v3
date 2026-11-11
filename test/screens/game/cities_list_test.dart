import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

import 'fake_game_session.dart';

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
      FakeGameSession(events.stream, UsersList([first, second])),
    );
    listKey = 0;
  });

  tearDown(() => events.close());

  // Builds a new CitiesList instance on every layout build, as the game
  // screen does.
  Widget app() => MaterialApp(
    home: RepositoryProvider<GameSessionRepository>.value(
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

  testWidgets('GameItemListTile highlights last letter', (tester) async {
    await tester.pumpWidget(app());
    await play(tester, 'рязань', first);

    final spans = <TextSpan>[];
    for (final text in tester.widgetList<RichText>(
      find.descendant(
        of: find.byType(GameItemListTile),
        matching: find.byType(RichText),
      ),
    )) {
      text.text.visitChildren((span) {
        if (span is TextSpan) spans.add(span);
        return true;
      });
    }

    final letter = spans.singleWhere((span) => span.text == 'н');
    expect(letter.style?.color, AppColors.light.letter);

    final tail = spans.singleWhere((span) => span.text == 'ь');
    expect(tail.style?.color, AppColors.light.inkSoft);
  });
}
