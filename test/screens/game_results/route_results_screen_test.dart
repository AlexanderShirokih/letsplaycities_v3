import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/game/hotseat_setup_screen.dart';
import 'package:lets_play_cities/screens/game/route/route_map.dart';
import 'package:lets_play_cities/screens/game_results/route_results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';

class _TestUser extends User {
  _TestUser(String name)
    : super(
        accountInfo: LocalAccountInfo(
          name: name,
          picture: const PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) =>
      throw UnimplementedError('not used');
}

void main() {
  final alice = _TestUser('Алиса');
  final bob = _TestUser('Боб');
  final world = WorldOutline.parse(_worldBytes());
  final t = AppLocale.ru.buildSync();

  RouteLeg leg(User owner, String? city, int country, int km, [GeoPoint? p]) =>
      RouteLeg(
        owner: owner,
        city: city,
        countryCode: country,
        point: p,
        km: km,
      );

  RouteState state(List<RouteLeg> legs) => RouteState(
    legs: legs,
    km: {
      alice: legs.where((l) => l.owner == alice).fold(0, (s, l) => s + l.km),
      bob: legs.where((l) => l.owner == bob).fold(0, (s, l) => s + l.km),
    },
    movesDone: legs.length,
  );

  final legs = [
    leg(alice, 'москва', 1, 0, const GeoPoint(55, 37)),
    leg(bob, 'париж', 2, 2500, const GeoPoint(48, 2)),
    leg(alice, null, 0, 0),
    leg(alice, 'осака', 3, 9000, const GeoPoint(34, 135)),
    leg(bob, 'токио', 3, 400, const GeoPoint(35, 139)),
    leg(alice, 'неизвестный', 0, 100),
  ];

  Future<void> pump(
    WidgetTester tester, {
    MatchResult match = MatchResult.win,
    MoveFinishType finish = MoveFinishType.routeCompleted,
    required List<RouteLeg> route,
    GameMode mode = GameMode.playerVsAndroid,
    Future<void> Function(BuildContext)? onShare,
    GamePreferences? prefs,
  }) {
    Widget app = withTranslations(
      MaterialApp(
        home: RouteResultsScreen(
          GameResult(
            owner: alice,
            opponent: bob,
            matchResult: match,
            finishType: finish,
            hasScore: false,
            finishRequester: alice,
            summary: GameSummary.empty,
            route: state(route),
          ),
          GameConfig(gameMode: mode),
          world: world,
          onShare: onShare,
        ),
      ),
    );

    if (prefs != null) {
      app = RepositoryProvider<GamePreferences>.value(value: prefs, child: app);
    }

    return tester.pumpWidget(app);
  }

  testWidgets('title follows the match result', (tester) async {
    await pump(tester, match: MatchResult.win, route: legs);
    expect(find.text(t.gameResults.winTitle), findsOneWidget);

    await pump(tester, match: MatchResult.lose, route: legs);
    expect(find.text(t.gameResults.loseTitle), findsOneWidget);

    await pump(tester, match: MatchResult.draw, route: legs);
    expect(find.text(t.gameResults.drawTitle), findsOneWidget);
  });

  testWidgets('metrics are counted from the route', (tester) async {
    await pump(tester, route: legs);

    // Countries 1, 2, 3: the unknown 0 is not counted
    expect(find.text('3'), findsOneWidget);
    // Accepted cities: the skip is not counted
    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('9 000'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Париж — Осака')), findsOneWidget);
  });

  testWidgets('metrics share the width 1 : 1.7 : 1', (tester) async {
    await pump(tester, route: legs);

    final countries = tester.getSize(find.text('стран'));
    final cities = tester.getSize(find.text('городов'));

    // A squeezed column would break the labels letter by letter
    expect(countries.height, lessThan(20));
    expect(cities.height, lessThan(20));
  });

  testWidgets('the reason is shown only for a game that ended early', (
    tester,
  ) async {
    final reason = t.gameResults.descSurrender(name: 'Алиса');

    await pump(tester, finish: MoveFinishType.routeCompleted, route: legs);
    expect(find.text(reason), findsNothing);

    await pump(tester, finish: MoveFinishType.surrender, route: legs);
    expect(find.text(reason), findsOneWidget);
  });

  testWidgets('the owner reads «Вы» against the computer only', (tester) async {
    await pump(tester, route: legs);
    expect(find.text(t.route.you), findsOneWidget);

    await pump(tester, mode: GameMode.playerVsPlayer, route: legs);
    expect(find.text(t.route.you), findsNothing);
    expect(find.text('Алиса'), findsOneWidget);
    expect(find.text('Боб'), findsOneWidget);
  });

  testWidgets('the map highlights the longest leg', (tester) async {
    await pump(tester, route: legs);

    final map = tester.widget<RouteMap>(find.byType(RouteMap));
    expect(map.highlight, legs[3]);
  });

  testWidgets('replay of a game of two players opens the names first', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SharedPreferencesGamePrefs(
      await SharedPreferences.getInstance(),
    )..hotseatNames = ['Аня', 'Боря'];
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pump(
      tester,
      mode: GameMode.playerVsPlayer,
      route: legs,
      prefs: prefs,
    );
    await tester.tap(find.text(t.gameResults.playAgain));
    await tester.pumpAndSettle();

    expect(find.byType(HotseatSetupScreen), findsOneWidget);
    expect(find.byType(RouteResultsScreen), findsNothing);
  });

  testWidgets('no share button without cities', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pump(tester, route: [leg(alice, null, 0, 0)]);
    expect(find.text(t.route.share), findsNothing);

    var shared = 0;
    await pump(tester, route: legs, onShare: (_) async => shared++);
    await tester.tap(find.text(t.route.share));
    expect(shared, 1);
  });

  testWidgets('a tap while the route is being shared is ignored', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var renders = 0;
    var pending = Completer<void>();
    await pump(
      tester,
      route: legs,
      onShare: (_) {
        renders++;
        return pending.future;
      },
    );

    await tester.tap(find.text(t.route.share));
    await tester.tap(find.text(t.route.share));
    expect(renders, 1);

    pending.complete();
    await tester.pump();
    pending = Completer<void>();

    await tester.tap(find.text(t.route.share));
    expect(renders, 2);

    pending.complete();
    await tester.pump();
  });

  testWidgets('a failed share is told about', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pump(
      tester,
      route: legs,
      onShare: (_) async => throw Exception('no share'),
    );

    await tester.tap(find.text(t.route.share));
    await tester.pump();
    expect(find.text(t.route.shareFailed), findsOneWidget);
  });
}

ByteData _worldBytes() {
  final data = ByteData(6 + 2 + 3 * 4);
  data.setUint16(0, 0x6E0E);
  data.setUint16(2, 1);
  data.setUint16(4, 1);
  data.setUint16(6, 3);
  final pts = [0, 0, 8000, 0, 8000, 8000];
  for (var i = 0; i < pts.length; i++) {
    data.setInt16(8 + i * 2, pts[i]);
  }

  return data;
}
