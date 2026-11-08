import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'online_fakes.dart';

void main() {
  group('OnlineProfileView', () {
    final t = AppLocale.ru.buildSync();
    late FakeApiRepository repository;
    late FakeAccountManager accountManager;

    setUp(() {
      registerFakeAchievements();
      repository = FakeApiRepository()..profiles = {2: userProfile(2, 'Alice')};
      accountManager = FakeAccountManager(remoteAccount(1, 'Bob'));
      GetIt.instance.registerSingleton<AccountManager>(accountManager);
    });

    Future<void> showAlicesProfile(WidgetTester tester) async {
      await tester.pumpWidget(
        hostScreen(const OnlineProfileView(userId: 2), repository: repository),
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

      expect(repository.log, ['putFriend(2)']);
      expect(find.text(t.online.cancelFriendshipRequest), findsOne);
    });

    testWidgets('opening skips the cache, the reload after an action uses it', (
      tester,
    ) async {
      await showAlicesProfile(tester);
      expect(repository.userCalls, [true]);

      await tester.tap(find.text(t.online.addToFriend));
      await tester.pumpAndSettle();

      expect(repository.userCalls, [true, false]);

      await pullToRefresh(tester);

      expect(repository.userCalls, [true, false, true]);
    });

    testWidgets('a refresh of the own profile asks for the account again', (
      tester,
    ) async {
      await tester.pumpWidget(
        hostScreen(const OnlineProfileView(), repository: repository),
      );
      await tester.pumpAndSettle();
      expect(accountManager.fetches, 1);

      await tester.drag(find.text('ID 1'), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(accountManager.invalidations, 1);
      expect(accountManager.fetches, 2);
    });

    group('actions by friendship and block', () {
      Future<void> show(
        WidgetTester tester, {
        Friendship friendship = Friendship.none,
        Blocked blocked = Blocked.none,
        void Function(LpsUser)? onInvite,
      }) async {
        repository.profiles = {
          2: userProfile(2, 'Alice', friendship: friendship, blocked: blocked),
        };
        await tester.pumpWidget(
          hostScreen(
            OnlineProfileView(userId: 2, onInvite: onInvite),
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();
      }

      for (final blocked in [Blocked.me, Blocked.both]) {
        testWidgets('profile hides invite when blocked is ${blocked.name}', (
          tester,
        ) async {
          await show(tester, friendship: Friendship.friends, blocked: blocked);

          expect(find.text(t.online.invite), findsNothing);
          expect(find.text(t.online.addToFriend), findsNothing);
          expect(find.text(t.online.inputBan), findsOneWidget);
        });
      }

      testWidgets('blocked by me offers only to unblock', (tester) async {
        await show(tester, blocked: Blocked.byMe);

        expect(find.text(t.online.unban), findsOneWidget);
        expect(find.text(t.online.addToFriend), findsNothing);
        expect(find.text(t.online.invite), findsNothing);
      });

      testWidgets('a friend can be invited', (tester) async {
        final invited = <int>[];
        await show(
          tester,
          friendship: Friendship.friends,
          onInvite: (u) => invited.add(u.id),
        );

        await tester.tap(find.text(t.online.invite));

        expect(invited, [2]);
      });

      testWidgets('an outgoing request can be cancelled', (tester) async {
        await show(tester, friendship: Friendship.outgoing);

        await tester.tap(find.text(t.online.cancelFriendshipRequest));
        await tester.pumpAndSettle();

        expect(repository.log, ['deleteFriend(2)']);
      });
    });
  });
}
