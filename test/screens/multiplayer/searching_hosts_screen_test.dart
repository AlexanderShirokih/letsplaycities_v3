import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/probe/network_discovery.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/multiplayer/searching_hosts_screen.dart';

import '../../i18n/translations_harness.dart';

class _FakeDiscovery extends NetworkDiscovery {
  final controllers = <StreamController<RemoteHost>>[];
  var scans = 0;
  final bool empty;

  _FakeDiscovery({this.empty = false}) : super(8988);

  StreamController<RemoteHost> get current => controllers.last;

  @override
  Stream<RemoteHost> scanHosts() {
    scans++;
    if (empty) return Stream.fromIterable(const []);
    final controller = StreamController<RemoteHost>();
    controllers.add(controller);
    return controller.stream;
  }

  @override
  void close() {}
}

const _host = RemoteHost(
  address: '192.168.1.24',
  versionName: '1.0',
  buildNumber: 1,
  hostName: 'Pixel Марии',
);

Widget _app(
  _FakeDiscovery discovery,
  void Function(RemoteHost?) onResult, {
  double textScale = 1,
}) => withTranslations(
  MaterialApp(
    theme: buildAppTheme(Brightness.light),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => onResult(
            await Navigator.push<RemoteHost?>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SearchingHostsScreen(createDiscovery: () => discovery),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('found hosts are listed and tap pops host', (tester) async {
    final discovery = _FakeDiscovery();
    RemoteHost? result;
    var popped = false;

    await tester.pumpWidget(
      _app(discovery, (host) {
        result = host;
        popped = true;
      }),
    );
    await _open(tester);

    expect(find.text('Игры рядом'), findsOneWidget);

    discovery.current.add(_host);
    await tester.pump();
    await tester.pump();

    expect(find.text('Pixel Марии'), findsOneWidget);
    expect(find.text('192.168.1.24'), findsOneWidget);

    await tester.tap(find.text('Pixel Марии'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(popped, isTrue);
    expect(result, same(_host));
  });

  testWidgets('empty finished search offers a retry', (tester) async {
    final discovery = _FakeDiscovery(empty: true);

    await tester.pumpWidget(_app(discovery, (_) {}));
    await _open(tester);

    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(discovery.scans, 1);

    await tester.tap(find.text('Повторить'));
    // Cancelling the finished scan completes in the real zone
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(discovery.scans, 2);
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('fits 320 px at text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final discovery = _FakeDiscovery();

    await tester.pumpWidget(_app(discovery, (_) {}, textScale: 1.3));
    await _open(tester);

    discovery.current
      ..add(_host)
      ..add(
        const RemoteHost(
          address: '192.168.100.200',
          versionName: '1.0',
          buildNumber: 1,
          hostName: 'Galaxy A54 Александра Викторовича',
        ),
      );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
