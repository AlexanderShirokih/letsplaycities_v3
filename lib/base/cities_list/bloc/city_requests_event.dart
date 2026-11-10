part of 'city_requests_bloc.dart';

abstract class CityRequestEvent extends Equatable {
  const CityRequestEvent();
}

class CityRequestFetchData extends CityRequestEvent {
  @override
  List<Object?> get props => [];
}

/// Withdraws the pending request [id] and loads the list again
class CityRequestWithdraw extends CityRequestEvent {
  final int id;

  const CityRequestWithdraw(this.id);

  @override
  List<Object?> get props => [id];
}
