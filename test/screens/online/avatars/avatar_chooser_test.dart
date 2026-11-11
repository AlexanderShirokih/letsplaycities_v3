import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/online/avatars/avatar_chooser.dart';

import '../../../i18n/translations_harness.dart';
import '../online_fakes.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  late FakeApiRepository repository;
  late int updates;

  setUp(() {
    repository = FakeApiRepository();
    GetIt.instance.registerSingleton<AccountManager>(FakeAccountManager(null));
    addTearDown(GetIt.instance.reset);
    updates = 0;
  });

  AvatarChooserView chooser() =>
      AvatarChooserView(repository, onAvatarUpdated: () => updates++);

  Future<void> openChooser(WidgetTester tester) async {
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showAppSheet<void>(context, builder: (_) => chooser()),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet has a title and three actions', (tester) async {
    await openChooser(tester);

    expect(find.text(t.online.avatarTitle), findsOneWidget);
    expect(find.text(t.misc.gallery), findsOneWidget);
    expect(find.text(t.misc.camera), findsOneWidget);
    expect(find.text(t.delete), findsOneWidget);
  });

  testWidgets('a failed removal closes the sheet with a message', (
    tester,
  ) async {
    repository.actionError = Exception('offline');
    await openChooser(tester);

    await tester.tap(find.text(t.delete));
    await tester.pumpAndSettle();

    expect(find.byType(AvatarChooserView), findsNothing);
    expect(find.text('Не удалось изменить аватар'), findsOneWidget);
    expect(updates, 0);
  });

  testWidgets('a refused picture shows the text of the error code', (
    tester,
  ) async {
    repository.actionError = const ApiException(400, 'too_large');
    await openChooser(tester);

    await tester.tap(find.text(t.delete));
    await tester.pumpAndSettle();

    expect(find.text(t.online.apiErrors['too_large']!), findsOneWidget);
  });

  testWidgets('dragging the sheet keeps it waiting for the removal', (
    tester,
  ) async {
    final removal = repository.actionsGate = Completer<void>();
    await openChooser(tester);

    await tester.tap(find.text(t.delete));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // The sheet builds a new view when a drag starts and ends.
    await tester.drag(
      find.byType(CircularProgressIndicator),
      const Offset(0, 20),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.delete), findsNothing);

    removal.complete();
    await tester.pumpAndSettle();
    expect(updates, 1);
    expect(find.byType(AvatarChooserView), findsNothing);
  });
}
