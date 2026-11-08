import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/auth_api.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/screens/common/authentication_view.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import '../../i18n/translations_harness.dart';
import '../../remote/auth/auth_api_test.dart' show userJson;
import '../../remote/fake_server.dart';
import '../online/online_fakes.dart';

class _Prefs extends Fake implements GamePreferences {
  @override
  bool signedOut = false;

  @override
  String lastNativeLogin = '';

  @override
  bool get onlineChatEnabled => true;
}

class _Device extends Fake implements SocialNetworksService {
  @override
  Future<String> getDeviceId() async => 'device-1';
}

void main() {
  late FakeServer server;
  late AccountManagerImpl manager;

  setUp(() {
    final config = AppConfig.forHost('lps.test');
    final tokens = MemoryTokenStore();
    final logger = SimpleErrorLogger();
    final factory = ApiRepositoryFactory.main(
      config,
      tokens,
      onError: logger.error,
    );
    final prefs = _Prefs();

    server = FakeServer()
      ..on('POST', '/v1/auth/native', 200, {
        'token': 'device-token',
        'user': userJson,
      })
      ..on('POST', '/v1/auth/logout', 204)
      ..on('PATCH', '/v1/me', 200, userJson)
      ..on('GET', '/v1/me', 200, userJson);

    manager = AccountManagerImpl(
      preferences: prefs,
      apiRepositories: factory,
      auth: AuthApi(factory.dio()..httpClientAdapter = server),
      socialNetworks: _Device(),
      messaging: StubCloudMessagingService(),
      logger: logger,
    );

    GetIt.instance
      ..registerSingleton<AccountManager>(manager)
      ..registerSingleton<GamePreferences>(prefs)
      ..registerSingleton<AchievementsService>(FakeAchievementsService());
    addTearDown(GetIt.instance.reset);
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: AuthenticationView(
            key: UniqueKey(),
            onLoggedIn: (_) => const Text('signed in'),
          ),
        ),
      ),
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  testWidgets('the device account signs in silently', (tester) async {
    await pumpView(tester);

    expect(find.text('signed in'), findsOneWidget);
    expect(server.calls, contains('POST /v1/auth/native'));
  });

  testWidgets('after sign-out the login screen comes without auth/native', (
    tester,
  ) async {
    await pumpView(tester);
    await tester.runAsync(manager.signOut);
    server.requests.clear();

    await pumpView(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(server.calls, isNot(contains('POST /v1/auth/native')));
  });
}
