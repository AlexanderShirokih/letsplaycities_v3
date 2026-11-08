import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/screens/online/game_request_view.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import '../../remote/fake_api_repository_factory.dart';
import 'online_fakes.dart';
import '../../i18n/translations_harness.dart';

/// Counts profile fetches; the account never arrives, so the view keeps
/// loading.
class _CountingAccountManager extends Fake implements AccountManager {
  final _never = Completer<RemoteAccount?>();
  int fetches = 0;

  @override
  Future<RemoteAccount?> getLastSignedInAccount() {
    fetches++;
    return _never.future;
  }
}

class _RequestsApiRepository extends FakeApiRepository {
  @override
  Future<void> declineGameRequest(BaseProfileInfo requester) async =>
      log.add('declineGameRequest(${requester.userId})');
}

void main() {
  setUp(() {
    GetIt.instance.registerSingleton<ErrorLogger>(SimpleErrorLogger());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('rebuilding the sheet keeps the request it is showing', (
    tester,
  ) async {
    final accountManager = _CountingAccountManager();
    GetIt.instance.registerSingleton<AccountManager>(accountManager);

    Widget sheet() => withTranslations(
      MaterialApp(
        home: Scaffold(
          body: GameRequestView(request: GameRequest('Alice', 2, 1)),
        ),
      ),
    );

    await tester.pumpWidget(sheet());
    await tester.pump();
    expect(accountManager.fetches, 1);

    // The bottom sheet builds a new view while it is dragged.
    await tester.pumpWidget(sheet());
    await tester.pump();
    expect(accountManager.fetches, 1);
  });

  testWidgets('a decline uses the account manager and the API factory '
      'registered when it is sent', (tester) async {
    // The sheet takes 30% of the screen height; the default test screen is
    // too short for the request and its buttons.
    tester.view.physicalSize = const Size(1200, 3000);
    addTearDown(tester.view.resetPhysicalSize);

    final repository = _RequestsApiRepository()
      ..profiles[2] = profileInfo(2, 'Alice');
    final accountManager = FakeAccountManager(remoteAccount(1, 'Bob'));
    final apiRepositories = FakeApiRepositoryFactory(repository);
    GetIt.instance
      ..registerSingleton<AccountManager>(accountManager)
      ..registerSingleton<ApiRepositoryFactory>(apiRepositories);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) =>
                      GameRequestView(request: GameRequest('Alice', 2, 1)),
                ),
                child: Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(accountManager.fetches, 1);

    // The profile was fetched through the factory registered then.
    expect(apiRepositories.userIds, [1]);

    // Stands in for the GetIt scope of a LAN game: the decline has to look
    // the manager and the factory up when it is sent, not when the sheet
    // opened.
    final lanRepository = _RequestsApiRepository();
    final lanApiRepositories = FakeApiRepositoryFactory(lanRepository);
    final lanAccountManager = FakeAccountManager(remoteAccount(3, 'Bob'));
    GetIt.instance
      ..pushNewScope()
      ..registerSingleton<AccountManager>(lanAccountManager)
      ..registerSingleton<ApiRepositoryFactory>(lanApiRepositories);

    await tester.tap(find.text(AppLocale.ru.buildSync().decline));
    await tester.pumpAndSettle();

    expect(accountManager.fetches, 1);
    expect(lanAccountManager.fetches, 1);
    expect(repository.log, isNot(contains('declineGameRequest(2)')));
    expect(lanRepository.log, ['declineGameRequest(2)']);
    expect(lanApiRepositories.userIds, [3]);
    expect(find.byType(GameRequestView), findsNothing);
  });
}
