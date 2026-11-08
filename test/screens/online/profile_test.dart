import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'online_fakes.dart';

void main() {
  group('formatLastVisit', () {
    final t = AppLocale.ru.buildSync();

    String lastVisit(DateTime date, {required DateTime now}) =>
        formatLastVisit(t, date, now);

    test('shows the time for a visit today', () {
      expect(
        lastVisit(
          DateTime(2026, 3, 1, 0, 5),
          now: DateTime(2026, 3, 1, 23, 50),
        ),
        'Был(а) в сети 00:05',
      );
    });

    test('shows "yesterday" for the previous day of another month', () {
      expect(
        lastVisit(
          DateTime(2026, 2, 28, 23, 50),
          now: DateTime(2026, 3, 1, 0, 10),
        ),
        'Был(а) в сети вчера, в 23:50',
      );
    });

    test('shows "yesterday" for the last day of the previous year', () {
      expect(
        lastVisit(DateTime(2025, 12, 31, 22, 0), now: DateTime(2026, 1, 1, 8)),
        'Был(а) в сети вчера, в 22:00',
      );
    });

    test('shows "yesterday" across a daylight saving change', () {
      expect(
        lastVisit(DateTime(2026, 3, 28, 10, 0), now: DateTime(2026, 3, 29, 23)),
        'Был(а) в сети вчера, в 10:00',
      );
    });

    test('shows the date for the same day of an earlier month', () {
      expect(
        lastVisit(DateTime(2026, 1, 7, 10, 0), now: DateTime(2026, 2, 7, 12)),
        'Был(а) в сети 07.01.2026',
      );
    });

    test('shows the date for a visit two days ago', () {
      expect(
        lastVisit(DateTime(2026, 3, 5, 12, 0), now: DateTime(2026, 3, 7, 9)),
        'Был(а) в сети 05.03.2026',
      );
    });
  });

  group('OnlineProfileView', () {
    final t = AppLocale.ru.buildSync();
    late FakeApiRepository repository;
    late FakeAccountManager accountManager;

    setUp(() {
      registerFakeAchievements();
      repository = FakeApiRepository()..profiles = {2: profileInfo(2, 'Alice')};
      accountManager = FakeAccountManager(remoteAccount(1, 'Bob'));
      GetIt.instance.registerSingleton<AccountManager>(accountManager);
    });

    Future<void> showAlicesProfile(WidgetTester tester) async {
      await tester.pumpWidget(
        hostScreen(
          OnlineProfileView(target: profileInfo(2, 'Alice')),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pullToRefresh(WidgetTester tester) async {
      await tester.drag(find.text('ID 2'), const Offset(0, 300));
      await tester.pumpAndSettle();
    }

    testWidgets('a failed account fetch offers a reload', (tester) async {
      accountManager.error = Exception('offline');
      await showAlicesProfile(tester);

      final reload = find.text(t.online.reload);
      expect(reload, findsOneWidget);

      accountManager.error = null;
      await tester.tap(reload);
      await tester.pumpAndSettle();

      expect(find.text('ID 2'), findsOneWidget);
      expect(accountManager.fetches, 2);
    });

    testWidgets('a refresh does not fetch the account again', (tester) async {
      await showAlicesProfile(tester);

      await pullToRefresh(tester);

      expect(find.text('ID 2'), findsOneWidget);
      expect(accountManager.fetches, 1);
    });

    testWidgets('a refresh during an action keeps waiting for its result', (
      tester,
    ) async {
      final request = repository.actionsGate = Completer<void>();
      await showAlicesProfile(tester);
      final addToFriends = find.ancestor(
        of: find.text(t.online.addToFriend),
        matching: find.byType(ElevatedButton),
      );

      await tester.tap(addToFriends);
      await pullToRefresh(tester);

      expect(tester.widget<ElevatedButton>(addToFriends).onPressed, isNull);

      request.complete();
      await tester.pumpAndSettle();

      expect(repository.log, ['sendNewFriendshipRequest(2)']);
      expect(find.text(t.online.cancelFriendshipRequest), findsOne);
    });
  });
}
