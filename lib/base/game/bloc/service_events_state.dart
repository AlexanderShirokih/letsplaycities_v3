part of 'service_events_bloc.dart';

/// State for [ServiceEventsBloc]
class ServiceEventsState extends Equatable {
  final bool isMessageFieldOpened;

  const ServiceEventsState({
    this.isMessageFieldOpened,
  });

  /// Creates a copy with customizable parameters
  ServiceEventsState copy({bool isMessageFieldOpened}) => ServiceEventsState(
        isMessageFieldOpened: isMessageFieldOpened ?? this.isMessageFieldOpened,
      );

  @override
  List<Object> get props => [isMessageFieldOpened];
}
