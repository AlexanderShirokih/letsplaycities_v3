import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';

import '../../i18n/translations_harness.dart';
import 'online_fakes.dart';

class _Prefs extends Fake implements GamePreferences {
  @override
  String lastNativeLogin = '';
}

/// Fails every sign-in with [error] and records the calls.
class _FailingAccountManager extends Fake implements AccountManager {
  _FailingAccountManager(this.error);

  final Object error;
  final calls = <String>[];

  @override
  Future<RemoteAccount> signInNative(String name) async {
    calls.add('native($name)');
    throw error;
  }

  @override
  Future<RemoteAccount> signInSocial(AuthType type) async {
    calls.add('social(${type.name})');
    throw error;
  }
}

void main() {
  final t = AppLocale.ru.buildSync();

  late _FailingAccountManager accountManager;

  void register(Object error, {String lastName = ''}) {
    accountManager = _FailingAccountManager(error);
    GetIt.instance
      ..registerSingleton<AccountManager>(accountManager)
      ..registerSingleton<GamePreferences>(_Prefs()..lastNativeLogin = lastName)
      ..registerSingleton<AchievementsService>(FakeAchievementsService());
    addTearDown(GetIt.instance.reset);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: LoginScreen(onLoggedIn: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  D2Button playButton(WidgetTester tester) =>
      tester.widget<D2Button>(find.widgetWithText(D2Button, t.login.play));

  testWidgets('login shows the D2 sign-in choices', (tester) async {
    register(const ApiException(500, 'internal'), lastName: 'Мария');
    await pump(tester);

    expect(find.text(t.online.title), findsOneWidget);
    expect(find.text(t.login.google), findsOneWidget);
    expect(find.text(t.login.vkId), findsOneWidget);
    expect(find.text(t.login.orGuest), findsOneWidget);
    expect(find.text('Мария'), findsOneWidget);
  });

  testWidgets('login play disabled for 1-char name', (tester) async {
    register(const ApiException(500, 'internal'));
    await pump(tester);

    expect(playButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), ' A  ');
    await tester.pump();
    expect(playButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Al');
    await tester.pump();
    expect(playButton(tester).onPressed, isNotNull);
  });

  testWidgets('login shows server message on forbidden_name', (tester) async {
    register(
      const ApiException(400, 'forbidden_name', 'Это имя использовать нельзя'),
    );
    await pump(tester);

    await tester.enterText(find.byType(TextField), ' Плохое ');
    await tester.pump();
    await tester.tap(find.text(t.login.play));
    await tester.pumpAndSettle();

    expect(accountManager.calls, ['native(Плохое)']);
    expect(find.text('Это имя использовать нельзя'), findsOneWidget);
  });

  testWidgets('an error without a message shows the text of its code', (
    tester,
  ) async {
    register(const ApiException(429, 'too_many_requests'));
    await pump(tester);

    await tester.tap(find.text(t.login.vkId));
    await tester.pumpAndSettle();

    expect(accountManager.calls, ['social(vkontakte)']);
    expect(find.text(t.login.errors['too_many_requests']!), findsOneWidget);
  });

  testWidgets('login fits 320px at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    register(const ApiException(500, 'internal'));

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: LoginScreen(onLoggedIn: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
