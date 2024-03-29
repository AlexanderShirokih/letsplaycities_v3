part of 'city_edit_actions_bloc.dart';

/// BLoC's states for [CityEditActionsBloc]
abstract class CityEditActionsState extends Equatable {
  const CityEditActionsState();
}

/// Initial state of city request manager screen
class CityEditActionsInitial extends CityEditActionsState {
  const CityEditActionsInitial();

  @override
  List<Object> get props => [];
}

/// State used when data is ready
class CityEditActionsData extends CityEditActionsState {
  /// All available countries
  final List<CountryEntity> countryEntities;

  /// Target city
  final CityItem cityItem;

  const CityEditActionsData(
    this.countryEntities,
    this.cityItem,
  );

  @override
  List<Object> get props => [countryEntities, cityItem];
}

/// State used when requested city is not found
class CityNotFound extends CityEditActionsState {
  final String city;

  const CityNotFound(this.city);

  @override
  List<Object?> get props => [city];
}

/// Describes error type
enum CityRequestSendingType {
  Network,
  NotAuthorized,
}

/// State when used was not authorized
class CityRequestSendingError extends CityEditActionsState {
  final CityRequestSendingType errorType;

  const CityRequestSendingError(this.errorType);

  @override
  List<Object?> get props => [errorType];
}

/// State used when request is sent
class CityRequestSent extends CityEditActionsState {
  const CityRequestSent();

  @override
  List<Object?> get props => [];
}
