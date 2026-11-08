import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/common/error_handler_widget.dart';

import '../../i18n/translations_harness.dart';

const _frame = Duration(milliseconds: 16);

void main() {
  _narrowTests();

  late bool dialogClosed;
  int? result;

  Future<void> openDialog(WidgetTester tester) async {
    dialogClosed = false;
    result = null;
    await tester.pumpWidget(
      withTranslations(const MaterialApp(home: Text('home'))),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showSingleChoiceDialog(context, 'Title', [
                      'A',
                      'B',
                      'C',
                    ], 0).then((value) {
                      dialogClosed = true;
                      result = value;
                    }),
                child: const Text('settings'),
              ),
            ),
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('settings'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpFrames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(_frame);
    }
  }

  testWidgets('two quick selections close only the dialog', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('B'));
    await pumpFrames(tester, 6);
    await tester.tap(find.text('C'));
    await pumpFrames(tester, 40);
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
    expect(dialogClosed, isTrue);
    expect(result, 2, reason: 'the last tapped choice wins');
  });

  testWidgets('cancel after a selection closes only the dialog', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(find.text('B'));
    await pumpFrames(tester, 12);
    await tester.tap(find.text(AppLocale.ru.buildSync().cancel.toUpperCase()));
    await pumpFrames(tester, 40);
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
    expect(dialogClosed, isTrue);
    expect(result, isNull);
  });

  testWidgets('a single selection returns its index', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('C'));
    await pumpFrames(tester, 40);
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
    expect(find.text('Title'), findsNothing);
    expect(result, 2);
  });

  testWidgets('a rebuild with another current choice keeps the selection', (
    tester,
  ) async {
    var currentChoice = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SingleChoiceDialog('Title', const [
                'A',
                'B',
                'C',
              ], currentChoice);
            },
          ),
        ),
      ),
    );

    rebuild(() => currentChoice = 2);
    await tester.pump();

    final group = tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>));
    expect(group.groupValue, 0);
  });
}

void _narrowTests() {
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

    await tester.tap(find.text(AppLocale.ru.buildSync().yes.toUpperCase()));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
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
    expect(find.text('trace-line'), findsNothing);

    await tester.tap(find.text(AppLocale.ru.buildSync().d2.details));
    await tester.pump();
    expect(find.text('trace-line'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
