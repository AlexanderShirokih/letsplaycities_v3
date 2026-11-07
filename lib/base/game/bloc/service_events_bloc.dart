import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'service_events_event.dart';

part 'service_events_state.dart';

/// Used for dispatching service UI events like opening/closing views
class ServiceEventsBloc extends Bloc<ServiceEventsEvent, ServiceEventsState>
    with SequentialEventMapping<ServiceEventsEvent, ServiceEventsState> {
  ServiceEventsBloc() : super(ServiceEventsState(isMessageFieldOpened: false)) {
    mapEventsSequentially(_mapEventToState);
  }

  Stream<ServiceEventsState> _mapEventToState(ServiceEventsEvent event) async* {
    switch (event) {
      case ServiceEventsEvent.ToggleMessageField:
        yield state.copy(isMessageFieldOpened: !state.isMessageFieldOpened);
        break;
    }
  }
}
