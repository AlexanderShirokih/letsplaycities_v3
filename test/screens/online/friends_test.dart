import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/screens/online/friends.dart';

import 'online_fakes.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  late FakeApiRepository repository;
  late FakeAchievementsService achievements;

  setUp(() {
    achievements = registerFakeAchievements();
    repository = FakeApiRepository()
      ..friends = [friendInfo(2, 'Alice', accepted: false)];
  });

  testWidgets('Accept sends the acceptance and reloads the list', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostScreen(const OnlineFriendsScreen(), repository: repository),
    );
    await tester.pumpAndSettle();

    final acceptLabel = t.online.acceptFriendshipRequest;
    await tester.tap(find.text(acceptLabel));
    await tester.pumpAndSettle();

    expect(repository.log, contains('sendFriendRequestAcceptance(2, true)'));
    expect(repository.log.last, 'getFriendsList(forceRefresh: true)');
    expect(find.text(t.online.requestAccepted), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(acceptLabel), findsNothing);
    expect(achievements.unlocked, [Achievement.add1Friend]);
  });

  testWidgets('a refused access shows the access-denied text', (tester) async {
    repository.listError = AccessDeniedException();

    await tester.pumpWidget(
      hostScreen(const OnlineFriendsScreen(), repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.errors.accessDenied), findsOneWidget);
  });
}
