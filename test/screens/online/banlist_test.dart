import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';

import 'online_fakes.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  late FakeApiRepository repository;
  late String removedMessage;

  setUp(() {
    removedMessage = t.online.banlistEntryRemoved;
    repository = FakeApiRepository()..banlist = [bannedUser(1, 'Bob')];
  });

  Future<void> showBanlist(WidgetTester tester) async {
    await tester.pumpWidget(
      hostScreen(const OnlineBanlistScreen(), repository: repository),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeAway(WidgetTester tester, String login) async {
    await tester.drag(find.text(login), const Offset(-600, 0));
    await tester.pumpAndSettle();
  }

  Future<void> letUndoSnackbarTimeOut(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('unbans a swiped user once the undo snackbar times out', (
    tester,
  ) async {
    await showBanlist(tester);

    await swipeAway(tester, 'Bob');
    expect(find.text(removedMessage), findsOneWidget);
    expect(repository.log, isNot(contains('removeFromBanlist(1)')));

    await letUndoSnackbarTimeOut(tester);

    expect(
      repository.log.where((call) => call == 'removeFromBanlist(1)'),
      hasLength(1),
    );
    expect(repository.log.last, 'getBanlist(forceRefresh: true)');
    expect(find.text('Bob'), findsNothing);
    // The undo snackbar has already said it, so it is not repeated.
    expect(find.text(removedMessage), findsNothing);
  });

  testWidgets('Cancel keeps the user banned and the next swipe asks again', (
    tester,
  ) async {
    await showBanlist(tester);

    await swipeAway(tester, 'Bob');
    await tester.tap(find.text(t.cancel));
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(repository.log, isNot(contains('removeFromBanlist(1)')));

    await swipeAway(tester, 'Bob');
    expect(find.text(removedMessage), findsOneWidget);

    await letUndoSnackbarTimeOut(tester);
    expect(repository.log, contains('removeFromBanlist(1)'));
  });

  testWidgets('a failed unban is reported and the user comes back', (
    tester,
  ) async {
    repository.actionError = Exception('offline');
    await showBanlist(tester);

    await swipeAway(tester, 'Bob');
    await letUndoSnackbarTimeOut(tester);

    expect(find.text('Не удалось выполнить действие'), findsOneWidget);
    expect(repository.log.last, 'getBanlist(forceRefresh: false)');
    expect(find.text('Bob'), findsOneWidget);
  });
}
