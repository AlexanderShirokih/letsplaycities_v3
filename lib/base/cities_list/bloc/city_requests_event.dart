part of 'city_requests_bloc.dart';

abstract class CityRequestEvent extends Equatable {
  const CityRequestEvent();
}

class CityRequestFetchData extends CityRequestEvent {
  @override
  List<Object?> get props => [];
}
