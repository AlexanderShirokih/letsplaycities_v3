import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';

import '../../i18n/translations_harness.dart';

void main() {
  testWidgets('back on the main menu closes the app right after launch', (
    tester,
  ) async {
    var exitRequests = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exitRequests++;
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
      withTranslations(
        const MaterialApp(home: Scaffold(body: AnimatedMainButtons())),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exitRequests, 1);

    // With the play submenu open, back returns to the primary buttons...
    await tester.tap(find.text('ИГРАТЬ'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exitRequests, 1);

    // ...and the next back closes the app.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exitRequests, 2);
  });
}
