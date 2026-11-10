import 'package:lets_play_cities/base/cities_list/city_request.dart';

/// LPS remote service client
abstract class LpsApiClient {
  const LpsApiClient();

  /// Gets a list of city requests
  Future<List<CityRequest>> getCityRequests();

  /// Sends a new city request and returns the created one
  Future<CityRequest> sendCityRequest(SendCityRequest request);

  /// Withdraws the own city request [id] that is not reviewed yet
  Future<void> deleteCityRequest(int id);
}
