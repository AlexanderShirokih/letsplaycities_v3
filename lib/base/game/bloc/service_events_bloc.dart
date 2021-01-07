import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'service_events_event.dart';

part 'service_events_state.dart';

/// Used for dispatching service UI events like opening/closing views
class ServiceEventsBloc extends Bloc<ServiceEventsEvent, ServiceEventsState> {
  ServiceEventsBloc() : super(ServiceEventsState(isMessageFieldOpened: false));

  @override
  Stream<ServiceEventsState> mapEventToState(ServiceEventsEvent event) async* {
    switch (event) {
      case ServiceEventsEvent.ToggleMessageField:
        yield state.copy(isMessageFieldOpened: !state.isMessageFieldOpened);
        break;
    }
  }
}
