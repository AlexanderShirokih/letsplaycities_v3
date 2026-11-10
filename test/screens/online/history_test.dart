import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/online/history.dart';

import 'online_fakes.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  late FakeApiRepository repository;
  final now = DateTime.now();

  HistoryGame game(
    int id,
    String opponent,
    DateTime startedAt, {
    bool isFriend = false,
    int words = 37,
    int durationSec = 252,
  }) => HistoryGame(
    id: id,
    opponent: lpsUser(id, opponent),
    isFriend: isFriend,
    startedAt: startedAt,
    durationSec: durationSec,
    words: words,
  );

  setUp(() {
    registerFakeAchievements();
    repository = FakeApiRepository();
  });

  Future<void> show(WidgetTester tester, {bool embedded = false}) async {
    await tester.pumpWidget(
      hostScreen(
        OnlineHistoryScreen(embedded: embedded),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty history shows the empty state', (tester) async {
    await show(tester);

    expect(find.text(t.online.historyEmptyTitle), findsOneWidget);
  });

  testWidgets('groups the games by months, the other years with the year', (
    tester,
  ) async {
    repository.games = [
      game(5, 'Maria', DateTime(now.year, 1, 12), isFriend: true),
      game(4, 'Timur', DateTime(now.year, 1, 9)),
      game(3, 'Anna', DateTime(now.year - 1, 12, 28)),
    ];

    await show(tester);

    expect(find.text(t.online.months[0]), findsOneWidget);
    expect(find.text('${t.online.months[11]} ${now.year - 1}'), findsOneWidget);
    expect(find.text('12 ${t.online.monthsShort[0]}'), findsOneWidget);
    expect(
      find.text(
        '${t.online.wordsCount(count: 37)} · '
        '${t.time.minutesSeconds(minutes: 4, seconds: 12)}',
      ),
      findsNWidgets(3),
    );
    // Only the friend has the mark
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == t.online.friendMark,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a month continued on the next page keeps one header', (
    tester,
  ) async {
    repository
      ..pageSize = 2
      ..games = [
        for (var i = 6; i >= 1; i--)
          game(i, 'Player $i', DateTime(now.year, 1, i)),
      ];
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await show(tester);

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text(t.online.months[0]), findsOneWidget);
    expect(repository.historyCalls.length, greaterThan(1));
  });

  testWidgets('embedded shows the compact rows without opponents', (
    tester,
  ) async {
    repository.games = [
      game(2, 'Maria', DateTime(now.year, 1, 12), isFriend: true),
      game(1, 'Maria', DateTime(now.year - 1, 11, 2), words: 54),
    ];

    await show(tester, embedded: true);

    expect(find.text('Maria'), findsNothing);
    expect(find.text('12 января'), findsOneWidget);
    expect(find.text('2 ноября ${now.year - 1}'), findsOneWidget);
    expect(find.text(t.online.wordsCount(count: 54)), findsOneWidget);
    expect(find.text(t.online.months[0]), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == t.online.friendMark,
      ),
      findsNothing,
    );
  });

  testWidgets('embedded draws nothing for an empty history', (tester) async {
    await show(tester, embedded: true);

    expect(find.text(t.online.historyEmptyTitle), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('long names do not overflow a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.games = [
      game(
        2,
        'A very long name ' * 6,
        DateTime(now.year, 1, 12),
        isFriend: true,
      ),
    ];

    await show(tester);
    expect(tester.takeException(), isNull);

    await show(tester, embedded: true);
    expect(tester.takeException(), isNull);
  });
}
