import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/common/error_handler_widget.dart';

import '../../i18n/translations_harness.dart';

void main() {
  Future<void> pumpNarrow(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: w!,
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('confirmation dialog returns the pressed answer', (tester) async {
    bool? answer;
    await pumpNarrow(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showConfirmationDialog(
            context,
            title: 'Title',
            message: 'Message',
          ).then((v) => answer = v),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);

    await tester.tap(find.text(AppLocale.ru.buildSync().yes));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });

  testWidgets('confirmation dialog shows its own labels', (tester) async {
    bool? answer;
    await pumpNarrow(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showConfirmationDialog(
            context,
            title: 'Title',
            message: 'Message',
            confirmLabel: 'Leave',
            cancelLabel: 'Stay',
            destructive: true,
          ).then((v) => answer = v),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Leave'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  testWidgets('loading and error views fit 320 px with a large font', (
    tester,
  ) async {
    await pumpNarrow(
      tester,
      Column(
        children: [
          const LoadingView('Loading'),
          Expanded(child: ErrorHandlerView('boom', 'trace-line')),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Loading'), findsOneWidget);
    final trace = find.textContaining('trace-line', findRichText: true);
    expect(trace, findsNothing);

    await tester.tap(find.text(AppLocale.ru.buildSync().d2.details));
    await tester.pump();
    expect(trace, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
