import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/home_screen.dart';

import '../../i18n/translations_harness.dart';

Widget _app(HomeActions actions) => withTranslations(
  MaterialApp(
    theme: buildD2Theme(Brightness.light),
    home: Scaffold(body: HomeScreen(actions: actions)),
  ),
);

final _noop = HomeActions(
  playVsComputer: () {},
  playTwoPlayers: () {},
  playWifi: () {},
  playOnline: () {},
  openSettings: () {},
  openProfile: () {},
);

void main() {
  testWidgets('home shows modes', (tester) async {
    await tester.pumpWidget(_app(_noop));

    expect(find.text('С компьютером'), findsOneWidget);
    expect(find.text('Играть'), findsOneWidget);
    expect(find.text('Вдвоём'), findsOneWidget);
    expect(find.text('По Wi-Fi'), findsOneWidget);
    expect(find.text('Онлайн'), findsOneWidget);
  });

  testWidgets('home tiles call actions', (tester) async {
    final calls = <String>[];
    final actions = HomeActions(
      playVsComputer: () => calls.add('pc'),
      playTwoPlayers: () => calls.add('two'),
      playWifi: () => calls.add('wifi'),
      playOnline: () => calls.add('online'),
      openSettings: () => calls.add('settings'),
      openProfile: () => calls.add('profile'),
    );
    await tester.pumpWidget(_app(actions));

    await tester.tap(find.text('Играть'));
    await tester.tap(find.text('Вдвоём'));
    await tester.tap(find.text('По Wi-Fi'));
    await tester.tap(find.text('Онлайн'));
    await tester.tap(find.byTooltip('Настройки'));
    await tester.tap(find.byTooltip('Профиль'));

    expect(calls, ['pc', 'two', 'wifi', 'online', 'settings', 'profile']);
  });

  testWidgets('home fits 320px at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(body: HomeScreen(actions: _noop)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('home avatar shows the signed-in account', (tester) async {
    final account = RemoteAccount(
      LpsUser(
        id: 1,
        name: 'мария',
        provider: 'native',
        lastSeenAt: DateTime(2026),
      ),
    );

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: Scaffold(
            body: HomeScreen(actions: _noop, loadAccount: () async => account),
          ),
        ),
      ),
    );
    await tester.pump();

    final avatar = tester.widget<D2Avatar>(
      find.descendant(
        of: find.byTooltip('Профиль'),
        matching: find.byType(D2Avatar),
      ),
    );
    expect(avatar.initials, 'М');
  });
}
