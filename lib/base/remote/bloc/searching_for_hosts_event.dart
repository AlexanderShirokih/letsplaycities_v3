part of 'searching_for_hosts_bloc.dart';

/// Base event class for [SearchingForHostsBloc]
abstract class SearchingForHostsEvent extends Equatable {
  const SearchingForHostsEvent();
}

/// Event used to start network scanning
class StartSearchingEvent extends SearchingForHostsEvent {
  @override
  List<Object?> get props => [];
}

/// Used internally to push new [RemoteHost]s
class AddRemoteHostEvent extends SearchingForHostsEvent {
  final HostSearchingResult results;

  AddRemoteHostEvent(this.results);

  @override
  List<Object?> get props => [results];
}
