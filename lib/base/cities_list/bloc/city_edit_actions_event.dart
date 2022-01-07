part of 'city_edit_actions_bloc.dart';

/// BLoC's events for [CityEditActionsBloc]
abstract class CityEditActions extends Equatable {
  const CityEditActions();
}

/// Used to trigger data loading
class CityEditActionFetchData extends CityEditActions {
  final String? city;

  const CityEditActionFetchData(this.city);

  @override
  List<Object?> get props => [city];
}

/// Sends changes as a new request
class CityEditActionSend extends CityEditActions {
  /// New city name
  final String updatedCityName;

  /// New country code
  final int updatedCountryCode;

  /// Editing reason
  final String reason;

  const CityEditActionSend({
    required this.reason,
    required this.updatedCityName,
    required this.updatedCountryCode,
  });

  @override
  List<Object?> get props => [reason, updatedCityName, updatedCountryCode];
}
