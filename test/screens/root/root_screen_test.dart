import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/root/root_screen.dart';

import '../../i18n/translations_harness.dart';

Widget _app(List<WidgetBuilder> tabs) => withTranslations(
  MaterialApp(
    theme: buildAppTheme(Brightness.light),
    home: Scaffold(body: RootScreen(tabsOverride: tabs)),
  ),
);

void main() {
  testWidgets('root builds tabs lazily', (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      _app([
        (_) => const Text('tab0'),
        (_) {
          builds++;
          return const Text('tab1');
        },
        (_) => const Text('tab2'),
      ]),
    );
    expect(builds, 0);

    await tester.tap(find.text('Города'));
    await tester.pump();
    expect(builds, 1);

    await tester.tap(find.text('Играть'));
    await tester.tap(find.text('Города'));
    await tester.pump();
    expect(builds, 1);
  });

  testWidgets('root switches tabs', (tester) async {
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      _app([(_) => Text('tab0'), (_) => Text('tab1'), (_) => Text('tab2')]),
    );

    await tester.tap(find.text('Города'));
    await tester.pump();
    expect(find.text('tab1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('tab0'), findsOneWidget);
    expect(exits, 0);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);
  });
}
