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

  const CityEditActionsData(this.countryEntities, this.cityItem);

  @override
  List<Object> get props => [countryEntities, cityItem];
}

/// State used when the city or the country list cannot be loaded
class CityDataLoadingError extends CityEditActionsState {
  const CityDataLoadingError();

  @override
  List<Object?> get props => [];
}

/// State used when requested city is not found
class CityNotFound extends CityEditActionsState {
  final String city;

  const CityNotFound(this.city);

  @override
  List<Object?> get props => [city];
}

/// Describes error type
enum CityRequestSendingType { network, notAuthorized, rejected }

/// State when the request was not sent
class CityRequestSendingError extends CityEditActionsState {
  final CityRequestSendingType errorType;

  /// The refusal of the server, set for [CityRequestSendingType.rejected]
  final ApiException? error;

  const CityRequestSendingError(this.errorType, [this.error]);

  @override
  List<Object?> get props => [errorType, error];
}

/// State used when request is sent
class CityRequestSent extends CityEditActionsState {
  const CityRequestSent();

  @override
  List<Object?> get props => [];
}
