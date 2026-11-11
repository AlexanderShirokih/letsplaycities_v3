import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/dictionary.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildAppTheme(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppButton calls onPressed and shows label', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(AppButton(label: 'Играть', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Играть'));

    expect(taps, 1);
  });

  testWidgets('disabled AppButton ignores taps', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(const AppButton(label: 'Играть')));
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

  testWidgets('pressed AppButton sinks by its shadow height', (tester) async {
    await tester.pumpWidget(_wrap(AppButton(label: 'Играть', onPressed: () {})));
    final top = tester.getTopLeft(find.text('Играть')).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Играть')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(find.text('Играть')).dy, top + 4);

    await gesture.up();
  });

  testWidgets('AppSegmented reports picked value', (tester) async {
    Difficulty? picked;

    await tester.pumpWidget(
      _wrap(
        AppSegmented<Difficulty>(
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

  testWidgets('AppSwitch toggles', (tester) async {
    bool? value;

    await tester.pumpWidget(
      _wrap(AppSwitch(value: false, onChanged: (v) => value = v)),
    );
    await tester.tap(find.byType(AppSwitch));

    expect(value, isTrue);
  });

  testWidgets('AppLetterTile has semantics label', (tester) async {
    await tester.pumpWidget(_wrap(const AppLetterTile('М')));

    expect(find.bySemanticsLabel('Буква хода: М'), findsOneWidget);
  });

  testWidgets('AppBottomNav selects tab', (tester) async {
    int? selected;

    await tester.pumpWidget(
      _wrap(AppBottomNav(index: 0, onSelect: (i) => selected = i)),
    );
    await tester.tap(find.text('Города'));

    expect(selected, 1);
  });

  testWidgets('AppIconButton exposes tooltip as semantics', (tester) async {
    await tester.pumpWidget(
      _wrap(AppIconButton(AppGlyph.back, tooltip: 'Назад', onPressed: () {})),
    );

    expect(find.bySemanticsLabel('Назад'), findsOneWidget);
  });

  testWidgets('AppIcon paints every glyph', (tester) async {
    await tester.pumpWidget(
      _wrap(Wrap(children: [for (final g in AppGlyph.values) AppIcon(g)])),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppIcon), findsNWidgets(AppGlyph.values.length));
  });

  testWidgets('logo, avatars, ring, header, card build', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const AppLogo(),
            const AppAvatar.computer(),
            const AppAvatar.user(initials: 'АБ'),
            const AppTimerRing(progress: 0.4, child: Text('12')),
            AppScreenHeader(title: 'Заголовок', onBack: () {}),
            const AppCard(child: Text('x')),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Заголовок'), findsOneWidget);
  });

  testWidgets('showAppSheet shows builder content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAppSheet<void>(context, builder: (_) => const Text('лист')),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('лист'), findsOneWidget);
  });

  testWidgets('AppEmptyState fits a short screen and runs its action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var taps = 0;

    await tester.pumpWidget(
      _wrap(
        AppEmptyState(
          art: const AppTileArt(glyph: AppGlyph.cities, badge: AppGlyph.plus),
          title: 'Заявок пока нет',
          text: 'Предложите город или правку — ответ появится здесь',
          actionLabel: 'Предложить город',
          onAction: () => taps++,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Заявок пока нет'), findsOneWidget);

    await tester.tap(find.text('Предложить город'));

    expect(taps, 1);
  });

  testWidgets('AppEmptyState without an action shows no button', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppEmptyState(art: AppBarsArt(), title: 'Пока пусто')),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppButton), findsNothing);
  });
}
