import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/bloc/states.dart';
import 'package:lets_play_cities/base/remote/bloc/searching_for_hosts_bloc.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/probe/network_discovery.dart';

/// Discovery whose results are pushed through [hosts].
class _FakeDiscovery extends NetworkDiscovery {
  _FakeDiscovery() : super(8988);

  final hosts = StreamController<RemoteHost>();
  var closed = false;

  @override
  Stream<RemoteHost> scanHosts() => hosts.stream;

  @override
  void close() => closed = true;
}

RemoteHost _host(String address) => RemoteHost(
  address: address,
  versionName: '1.0',
  buildNumber: 1,
  hostName: address,
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('Shows each host as soon as it is found', () async {
    final discovery = _FakeDiscovery();
    final bloc = SearchingForHostsBloc(discovery: discovery);
    final states = <BaseState<HostSearchingResult>>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(StartSearchingEvent());
    await _settle();
    for (final address in ['192.168.1.10', '192.168.1.20', '192.168.1.30']) {
      discovery.hosts.add(_host(address));
      await _settle();
    }
    await discovery.hosts.close();
    await _settle();

    final results = states
        .whereType<DataState<HostSearchingResult>>()
        .map((s) => (s.data.availableHosts.length, s.data.isCompleted))
        .toList();
    expect(results, [(1, false), (2, false), (3, false), (3, true)]);

    await subscription.cancel();
    await bloc.close();
  });

  test('Closes the discovery it was given', () async {
    final discovery = _FakeDiscovery();
    final bloc = SearchingForHostsBloc(discovery: discovery)
      ..add(StartSearchingEvent());
    await _settle();

    await bloc.close();

    expect(discovery.closed, isTrue);
    expect(discovery.hosts.hasListener, isFalse);
  });
}
