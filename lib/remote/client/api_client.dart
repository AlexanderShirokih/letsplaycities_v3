import 'package:lets_play_cities/base/cities_list/city_request.dart';

/// LPS remote service client
abstract class LpsApiClient {
  const LpsApiClient();

  /// Gets a list of city requests
  Future<List<CityRequest>> getCityRequests();

  /// Sends a new city request
  Future<void> sendCityRequest(SendCityRequest request);
}
