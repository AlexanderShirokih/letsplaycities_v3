import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';

import 'online_fakes.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  late FakeApiRepository repository;
  late String removedMessage;

  setUp(() {
    registerFakeAchievements();
    removedMessage = t.online.banlistEntryRemoved;
    repository = FakeApiRepository()..blocked = [lpsUser(1, 'Bob')];
  });

  Future<void> showBanlist(WidgetTester tester) async {
    await tester.pumpWidget(
      hostScreen(const OnlineBanlistScreen(), repository: repository),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unban(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(t.online.unbanNamed(name: 'Bob')));
    await tester.pumpAndSettle();
  }

  Future<void> letUndoSnackbarTimeOut(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('unbans a user once the undo snackbar times out', (tester) async {
    await showBanlist(tester);

    await unban(tester);
    expect(find.text(removedMessage), findsOneWidget);
    // The row leaves at once, the request waits for the snackbar.
    expect(find.text('Bob'), findsNothing);
    expect(repository.log, isNot(contains('deleteBlock(1)')));

    await letUndoSnackbarTimeOut(tester);

    expect(
      repository.log.where((call) => call == 'deleteBlock(1)'),
      hasLength(1),
    );
    expect(repository.log.last, 'blocks(forceRefresh: false)');
    expect(find.text('Bob'), findsNothing);
    // The undo snackbar has already said it, so it is not repeated.
    expect(find.text(removedMessage), findsNothing);
  });

  testWidgets('Cancel keeps the user banned and the next unban asks again', (
    tester,
  ) async {
    await showBanlist(tester);

    await unban(tester);
    await tester.tap(find.text(t.cancel));
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(repository.log, isNot(contains('deleteBlock(1)')));

    await unban(tester);
    expect(find.text(removedMessage), findsOneWidget);

    await letUndoSnackbarTimeOut(tester);
    expect(repository.log, contains('deleteBlock(1)'));
  });

  testWidgets('a failed unban is reported and the user comes back', (
    tester,
  ) async {
    repository.actionError = Exception('offline');
    await showBanlist(tester);

    await unban(tester);
    await letUndoSnackbarTimeOut(tester);

    expect(find.text('Не удалось выполнить действие'), findsOneWidget);
    expect(repository.log.last, 'blocks(forceRefresh: false)');
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('an empty list shows the empty state', (tester) async {
    repository.blocked = [];

    await showBanlist(tester);

    expect(find.text(t.online.blacklistEmptyTitle), findsOneWidget);
    expect(find.text(t.online.unban), findsNothing);
  });

  testWidgets('a long name is cut instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(400, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.blocked = [lpsUser(1, 'A very long name ' * 6)];

    await showBanlist(tester);

    expect(tester.takeException(), isNull);
  });
}
