import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as theme;
import 'package:lets_play_cities/screens/main_widget.dart';

theme.Theme _theme(String name) => theme.Theme(
  name: name,
  primaryColor: Colors.blue,
  accentColor: Colors.blue,
  fillColor: Colors.white,
  borderColor: Colors.white,
  messageMe: Colors.white,
  messageOther: Colors.white,
);

void main() {
  testWidgets('the provided theme follows system brightness changes', (
    tester,
  ) async {
    final light = _theme('light');
    final dark = _theme('dark');
    theme.Theme? provided;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(
      SystemBrightnessThemeProvider(
        current: light,
        dark: dark,
        child: Builder(
          builder: (context) {
            provided = context.watch<theme.Theme>();
            return const SizedBox();
          },
        ),
      ),
    );
    expect(provided, light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    expect(provided, dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(provided, light);
  });
}
