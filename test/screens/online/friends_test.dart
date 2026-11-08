import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/online/friends.dart';

import 'online_fakes.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  late FakeApiRepository repository;
  late FakeAchievementsService achievements;

  setUp(() {
    achievements = registerFakeAchievements();
    repository = FakeApiRepository()
      ..friendEntries = [friendEntry(2, 'Alice', FriendStatus.incoming)];
  });

  Future<void> show(
    WidgetTester tester, {
    void Function(LpsUser)? onInvite,
  }) async {
    await tester.pumpWidget(
      hostScreen(
        OnlineFriendsScreen(onInvite: onInvite),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Accept sends the acceptance and reloads the list', (
    tester,
  ) async {
    await show(tester);

    final acceptLabel = t.online.acceptFriendshipRequest;
    await tester.tap(find.text(acceptLabel));
    await tester.pumpAndSettle();

    expect(repository.log, contains('putFriend(2)'));
    // The repository keeps its cache right after an action
    expect(repository.log.last, 'friends(forceRefresh: false)');
    expect(find.text(t.online.requestAccepted), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(acceptLabel), findsNothing);
    expect(achievements.unlocked, [Achievement.add1Friend]);
  });

  testWidgets('a refused access shows the access-denied text', (tester) async {
    repository.listError = const UnauthorizedException(401, 'unauthorized');

    await show(tester);

    expect(find.text(t.errors.accessDenied), findsOneWidget);
  });

  testWidgets('friends screen splits incoming, outgoing and friends', (
    tester,
  ) async {
    final now = DateTime.now();
    repository.friendEntries = [
      friendEntry(2, 'Alice', FriendStatus.incoming),
      friendEntry(3, 'Bob', FriendStatus.outgoing),
      friendEntry(4, 'Carol', FriendStatus.friends, lastSeenAt: now),
      friendEntry(
        5,
        'Dave',
        FriendStatus.friends,
        lastSeenAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    await show(tester);

    expect(find.text(t.online.friendRequests), findsOneWidget);
    expect(find.text(t.online.acceptFriendshipRequest), findsOneWidget);
    expect(find.text(t.online.declineFriendshipRequest), findsOneWidget);
    expect(find.text(t.online.requestSent), findsOneWidget);
    expect(find.text(t.online.cancelFriendshipRequest), findsOneWidget);
    expect(find.text(t.online.myFriends), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(t.online.lastSeen.now), findsOneWidget);
    expect(find.text(t.online.lastSeen.daysAgo(count: 3)), findsOneWidget);
    // Only the online friend can be invited
    expect(find.text(t.online.inviteShort), findsOneWidget);
  });

  testWidgets('Invite calls back with the friend', (tester) async {
    repository.friendEntries = [
      friendEntry(4, 'Carol', FriendStatus.friends, lastSeenAt: DateTime.now()),
    ];
    final invited = <int>[];

    await show(tester, onInvite: (friend) => invited.add(friend.id));
    await tester.tap(find.text(t.online.inviteShort));

    expect(invited, [4]);
  });

  testWidgets('friends search filters by id', (tester) async {
    repository.friendEntries = [
      friendEntry(31877, 'Timur', FriendStatus.friends),
      friendEntry(7, 'Maria', FriendStatus.friends),
    ];
    await show(tester);

    await tester.enterText(find.byType(EditableText), '31877');
    await tester.pumpAndSettle();

    expect(find.text('Timur'), findsOneWidget);
    expect(find.text('Maria'), findsNothing);

    await tester.enterText(find.byType(EditableText), 'mar');
    await tester.pumpAndSettle();

    expect(find.text('Timur'), findsNothing);
    expect(find.text('Maria'), findsOneWidget);
  });

  testWidgets('opening the screen skips the cache, an action reload uses it', (
    tester,
  ) async {
    await show(tester);
    expect(repository.log, ['friends(forceRefresh: true)']);

    await tester.tap(find.text(t.online.declineFriendshipRequest));
    await tester.pumpAndSettle();

    expect(repository.log, [
      'friends(forceRefresh: true)',
      'deleteFriend(2)',
      'friends(forceRefresh: false)',
    ]);
  });

  Future<void> openMenu(WidgetTester tester, String name) async {
    await tester.tap(find.byTooltip(name));
    await tester.pumpAndSettle();
  }

  testWidgets('the menu blocks a friend', (tester) async {
    repository.friendEntries = [friendEntry(4, 'Carol', FriendStatus.friends)];
    await show(tester);

    await openMenu(tester, 'Carol');
    await tester.tap(find.text(t.online.ban));
    await tester.pumpAndSettle();

    expect(repository.log, contains('putBlock(4)'));
  });

  testWidgets('the menu removes a friend once the undo snackbar times out', (
    tester,
  ) async {
    repository.friendEntries = [friendEntry(4, 'Carol', FriendStatus.friends)];
    await show(tester);

    await openMenu(tester, 'Carol');
    await tester.tap(find.text(t.online.removeFromFriends));
    await tester.pumpAndSettle();
    expect(find.text(t.online.removedFromFriends(login: 'Carol')), findsOne);
    expect(repository.log, isNot(contains('deleteFriend(4)')));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(repository.log, contains('deleteFriend(4)'));
    expect(find.text('Carol'), findsNothing);
  });

  testWidgets('Cancel on the undo snackbar keeps the friend', (tester) async {
    repository.friendEntries = [friendEntry(4, 'Carol', FriendStatus.friends)];
    await show(tester);

    await openMenu(tester, 'Carol');
    await tester.tap(find.text(t.online.removeFromFriends));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.cancel));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(repository.log, isNot(contains('deleteFriend(4)')));
    expect(find.text('Carol'), findsOneWidget);
  });

  testWidgets('the search text survives the reload after an action', (
    tester,
  ) async {
    repository.friendEntries = [
      friendEntry(2, 'Alice', FriendStatus.incoming),
      friendEntry(7, 'Maria', FriendStatus.friends),
      friendEntry(8, 'Timur', FriendStatus.friends),
    ];
    await show(tester);

    await tester.enterText(find.byType(EditableText), 'ali');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.online.acceptFriendshipRequest));
    await tester.pumpAndSettle();

    expect(repository.log.last, 'friends(forceRefresh: false)');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'ali',
    );
    // Alice is a friend now and matches the search
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Maria'), findsNothing);
  });

  testWidgets('the friend count ignores the search', (tester) async {
    repository.friendEntries = [
      friendEntry(7, 'Maria', FriendStatus.friends),
      friendEntry(8, 'Timur', FriendStatus.friends),
    ];
    await show(tester);

    await tester.enterText(find.byType(EditableText), 'mar');
    await tester.pumpAndSettle();

    expect(find.text('Timur'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('a failed action shows the text of the server', (tester) async {
    repository.actionError = const ApiException(403, 'blocked', 'Blocked!');
    await show(tester);

    await tester.tap(find.text(t.online.acceptFriendshipRequest));
    await tester.pumpAndSettle();

    expect(find.text('Blocked!'), findsOneWidget);
  });
}
