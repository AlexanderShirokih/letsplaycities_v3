import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';
import 'package:lets_play_cities/base/bloc/states.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/probe/network_discovery.dart';

part 'searching_for_hosts_event.dart';

/// Class that wraps searching results
class HostSearchingResult extends Equatable {
  final List<RemoteHost> availableHosts;
  final bool isCompleted;

  const HostSearchingResult(this.availableHosts, {required this.isCompleted});

  @override
  List<Object?> get props => [availableHosts, isCompleted];
}

class SearchingForHostsBloc
    extends Bloc<SearchingForHostsEvent, BaseState<HostSearchingResult>>
    with
        SequentialEventMapping<
          SearchingForHostsEvent,
          BaseState<HostSearchingResult>
        > {
  final NetworkDiscovery _discovery;

  final List<RemoteHost> _hosts = [];
  StreamSubscription<RemoteHost>? _discoverySubscription;

  /// The bloc owns the given discovery and closes it in [close].
  SearchingForHostsBloc({required this._discovery}) : super(InitialState()) {
    mapEventsSequentially(_mapEventToState);
  }

  Stream<BaseState<HostSearchingResult>> _mapEventToState(
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

    // Each result gets its own copy of the list: a state that shares the
    // growing list equals the next one, and the bloc would skip it.
    _discoverySubscription = _discovery.scanHosts().listen(
      (host) {
        _hosts.add(host);
        add(
          AddRemoteHostEvent(
            HostSearchingResult(List.unmodifiable(_hosts), isCompleted: false),
          ),
        );
      },
      onDone: () {
        add(
          AddRemoteHostEvent(
            HostSearchingResult(List.unmodifiable(_hosts), isCompleted: true),
          ),
        );
      },
    );
  }
}
