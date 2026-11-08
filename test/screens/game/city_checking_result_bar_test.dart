import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/management/word_checking_result.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/screens/game/city_checking_result_bar.dart';

import '../../i18n/translations_harness.dart';

class _FakeGameSession extends Fake implements GameSession {
  final results = StreamController<WordCheckingResult>.broadcast();

  /// A new stream object on every call, like [GameSession].
  @override
  Stream<WordCheckingResult> get wordCheckingResults =>
      results.stream.where((_) => true);
}

void main() {
  late _FakeGameSession session;
  late StateSetter rebuildLayout;

  setUp(() => session = _FakeGameSession());

  tearDown(() => session.results.close());

  Future<void> pumpBar(WidgetTester tester) async {
    final barKey = GlobalKey();
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider(
              create: (_) => GameSessionRepository(session),
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuildLayout = setState;
                  // Not const, so a layout rebuild updates the bar.
                  return CityCheckingResultBar(key: barKey);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double barSize(WidgetTester tester) => tester
      .widget<SizeTransition>(find.byType(SizeTransition))
      .sizeFactor
      .value;

  /// Delivers [result] and lets its animation run for half a second.
  Future<void> showResult(
    WidgetTester tester,
    WordCheckingResult result,
  ) async {
    session.results.add(result);
    // The first pump delivers the event, the second starts the animation.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('each error message shows up and hides again', (tester) async {
    await pumpBar(tester);

    await showResult(tester, const AlreadyUsed('москва'));
    expect(barSize(tester), greaterThan(0));

    await tester.pumpAndSettle();
    expect(barSize(tester), 0);

    await showResult(tester, const NotFound('масква'));
    expect(barSize(tester), greaterThan(0));
  });

  testWidgets('a hidden error message stays hidden when the layout rebuilds', (
    tester,
  ) async {
    await pumpBar(tester);
    await showResult(tester, const AlreadyUsed('москва'));
    await tester.pumpAndSettle();

    rebuildLayout(() {});
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(barSize(tester), 0);
  });
}
