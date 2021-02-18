import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/presentation/states.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/probe/network_discovery.dart';

part 'searching_for_hosts_event.dart';

/// Class that wraps searching results
class HostSearchingResult extends Equatable {
  final List<RemoteHost> availableHosts;
  final bool isCompleted;

  HostSearchingResult(this.availableHosts, {required this.isCompleted});

  @override
  List<Object?> get props => [availableHosts, isCompleted];
}

class SearchingForHostsBloc
    extends Bloc<SearchingForHostsEvent, BaseState<HostSearchingResult>> {
  final NetworkDiscovery _discovery;

  final List<RemoteHost> _hosts = [];
  StreamSubscription<RemoteHost>? _discoverySubscription;

  SearchingForHostsBloc()
      : _discovery = NetworkDiscovery.createDiscovery(
          port: GetIt.instance.get<AppConfig>(instanceName: 'local').port,
        ),
        super(InitialState());

  @override
  Stream<BaseState<HostSearchingResult>> mapEventToState(
    SearchingForHostsEvent event,
  ) async* {
    if (event is StartSearchingEvent) {
      yield* _startSearching();
    } else if (event is AddRemoteHostEvent) {
      yield DataState(event.results);
    }
  }

  @override
  Future<void> close() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    _discovery.close();
    _hosts.clear();
    await super.close();
  }

  Stream<BaseState<HostSearchingResult>> _startSearching() async* {
    await _discoverySubscription?.cancel();
    _hosts.clear();

    yield LoadingState<HostSearchingResult>();

    _discoverySubscription = _discovery.scanHosts().listen(
      (host) {
        _hosts.add(host);
        add(
          AddRemoteHostEvent(HostSearchingResult(_hosts, isCompleted: false)),
        );
      },
      onDone: () {
        add(
          AddRemoteHostEvent(HostSearchingResult(_hosts, isCompleted: true)),
        );
      },
    );
  }
}
