import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/dictionary.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildD2Theme(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('D2Button calls onPressed and shows label', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(D2Button(label: 'Играть', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Играть'));

    expect(taps, 1);
  });

  testWidgets('disabled D2Button ignores taps', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(const D2Button(label: 'Играть')));
    final top = tester.getTopLeft(find.text('Играть')).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Играть')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(find.text('Играть')).dy, top);
    expect(
      tester.getSemantics(find.text('Играть')),
      isSemantics(label: 'Играть', isEnabled: false, isButton: true),
    );

    await gesture.up();
    handle.dispose();
  });

  testWidgets('pressed D2Button sinks by its shadow height', (tester) async {
    await tester.pumpWidget(_wrap(D2Button(label: 'Играть', onPressed: () {})));
    final top = tester.getTopLeft(find.text('Играть')).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Играть')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(find.text('Играть')).dy, top + 4);

    await gesture.up();
  });

  testWidgets('D2Segmented reports picked value', (tester) async {
    Difficulty? picked;

    await tester.pumpWidget(
      _wrap(
        D2Segmented<Difficulty>(
          items: const [
            (Difficulty.easy, 'Легко'),
            (Difficulty.medium, 'Нормально'),
            (Difficulty.hard, 'Сложно'),
          ],
          selected: Difficulty.easy,
          onChanged: (v) => picked = v,
        ),
      ),
    );
    await tester.tap(find.text('Сложно'));

    expect(picked, Difficulty.hard);
    expect(
      tester.getSemantics(find.text('Легко')),
      isSemantics(label: 'Легко', isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('Сложно')),
      isSemantics(label: 'Сложно', isSelected: false),
    );
  });

  testWidgets('D2Switch toggles', (tester) async {
    bool? value;

    await tester.pumpWidget(
      _wrap(D2Switch(value: false, onChanged: (v) => value = v)),
    );
    await tester.tap(find.byType(D2Switch));

    expect(value, isTrue);
  });

  testWidgets('D2LetterTile has semantics label', (tester) async {
    await tester.pumpWidget(_wrap(const D2LetterTile('М')));

    expect(find.bySemanticsLabel('Буква хода: М'), findsOneWidget);
  });

  testWidgets('D2BottomNav selects tab', (tester) async {
    int? selected;

    await tester.pumpWidget(
      _wrap(D2BottomNav(index: 0, onSelect: (i) => selected = i)),
    );
    await tester.tap(find.text('Города'));

    expect(selected, 1);
  });

  testWidgets('D2IconButton exposes tooltip as semantics', (tester) async {
    await tester.pumpWidget(
      _wrap(D2IconButton(D2Glyph.back, tooltip: 'Назад', onPressed: () {})),
    );

    expect(find.bySemanticsLabel('Назад'), findsOneWidget);
  });

  testWidgets('D2Icon paints every glyph', (tester) async {
    await tester.pumpWidget(
      _wrap(Wrap(children: [for (final g in D2Glyph.values) D2Icon(g)])),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(D2Icon), findsNWidgets(D2Glyph.values.length));
  });

  testWidgets('logo, avatars, ring, header, card build', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const D2Logo(),
            const D2Avatar.computer(),
            const D2Avatar.user(initials: 'АБ'),
            const D2TimerRing(progress: 0.4, child: Text('12')),
            D2ScreenHeader(title: 'Заголовок', onBack: () {}),
            const D2Card(child: Text('x')),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Заголовок'), findsOneWidget);
  });

  testWidgets('showD2Sheet shows builder content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildD2Theme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showD2Sheet<void>(context, builder: (_) => const Text('лист')),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('лист'), findsOneWidget);
  });
}
