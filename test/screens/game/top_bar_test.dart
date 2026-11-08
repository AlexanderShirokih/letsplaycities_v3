import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/chat_sheet.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/screens/game/top_bar.dart';

import '../../i18n/translations_harness.dart';
import 'fake_game_session.dart';

class _ChatAccount extends ClientAccountInfo {
  @override
  final String name;

  const _ChatAccount(this.name);

  @override
  PictureSource get picture => const PlaceholderPictureSource();

  @override
  bool get canReceiveMessages => true;
}

/// The other side of a network game
class _Opponent extends User {
  _Opponent()
    : super(
        accountInfo: const _ChatAccount('Мария'),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) => Completer<String>().future;
}

void main() {
  final t = AppLocale.ru.buildSync();

  late StreamController<GameEvent> events;
  late Player me;
  late _Opponent opponent;

  setUp(() {
    events = StreamController<GameEvent>.broadcast();
    me = Player(const _ChatAccount('Вы'));
    opponent = _Opponent();
  });

  tearDown(() => events.close());

  Future<void> pumpBar(WidgetTester tester, GameMode mode) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = GameSessionRepository(
      FakeGameSession(events.stream, UsersList([me, opponent]), mode: mode),
    );

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: Scaffold(
                body: RepositoryProvider.value(
                  value: repository,
                  child: Column(
                    children: [
                      TopBar(GameConfig(gameMode: mode)),
                      const CitiesList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(ChatSheet), matching: finder);

  testWidgets('game against the computer shows the hint and the full menu', (
    tester,
  ) async {
    await pumpBar(tester, GameMode.playerVsAndroid);

    expect(tester.takeException(), isNull);
    expect(find.text(t.game.hint), findsOneWidget);
    expect(find.text(t.game.chat), findsNothing);

    await tester.tap(find.text(t.game.pause));
    await tester.pumpAndSettle();

    expect(find.text(t.game.resume), findsOneWidget);
    expect(find.text(t.game.rules), findsOneWidget);
    expect(find.text(t.game.exitToMenu), findsOneWidget);
    expect(find.text(t.game.surrenderMenu), findsOneWidget);
  });

  testWidgets('network game shows the chat and a short menu', (tester) async {
    await pumpBar(tester, GameMode.network);

    expect(tester.takeException(), isNull);
    expect(find.text(t.game.chat), findsOneWidget);
    expect(find.text(t.game.hint), findsNothing);

    await tester.tap(find.text(t.game.pause));
    await tester.pumpAndSettle();

    expect(find.text(t.game.resume), findsNothing);
    expect(find.text(t.game.rules), findsNothing);
    expect(find.text(t.game.exitToMenu), findsOneWidget);
    expect(find.text(t.game.surrenderMenu), findsOneWidget);
  });

  testWidgets('chat counts opponent messages until the chat is opened', (
    tester,
  ) async {
    await pumpBar(tester, GameMode.network);

    events.add(MessageEvent('Привет!', opponent));
    events.add(MessageEvent('Удачи!', opponent));
    events.add(MessageEvent('И тебе', me));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel(t.game.chatUnread(count: 2)), findsOneWidget);

    await tester.tap(find.text(t.game.chat));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Привет!')), findsOneWidget);
    expect(inSheet(find.text('И тебе')), findsOneWidget);
    expect(find.text('2'), findsNothing);

    events.add(MessageEvent('Ход!', opponent));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Ход!')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.d2.close));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSheet), findsNothing);
    expect(find.text('1'), findsNothing);

    events.add(MessageEvent('Ну?', opponent));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}
