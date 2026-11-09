import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/game_results/route_share_card.dart';

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
  final t = AppLocale.ru.buildSync();

  final legs = [
    RouteLeg(
      owner: alice,
      city: 'москва',
      countryCode: 1,
      point: const GeoPoint(55, 37),
      km: 0,
    ),
    RouteLeg(
      owner: bob,
      city: 'париж',
      countryCode: 2,
      point: const GeoPoint(48, 2),
      km: 2500,
    ),
    RouteLeg(
      owner: alice,
      city: 'осака',
      countryCode: 3,
      point: const GeoPoint(34, 135),
      km: 9000,
    ),
  ];

  final route = RouteState(
    legs: legs,
    km: {alice: 9000, bob: 2500},
    movesDone: 3,
  );

  testWidgets('the card renders the km of both players', (tester) async {
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          home: RouteShareCard(
            world: WorldOutline.parse(_worldBytes()),
            route: route,
            owner: alice,
            opponent: bob,
            matchResult: MatchResult.win,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('9 000'), findsOneWidget);
    expect(find.textContaining('2 500'), findsOneWidget);
    expect(find.text(t.gameResults.winTitle), findsOneWidget);
  });

  test('the share text has the km and the countries of the owner', () {
    expect(
      routeShareText(t, route, alice),
      allOf(contains('9 000 км'), contains('3 страны')),
    );
    expect(routeShareText(t, route, alice), contains('play.google.com'));
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
