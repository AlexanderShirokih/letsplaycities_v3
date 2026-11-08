import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';

/// LPS remote service client
abstract class LpsApiClient {
  const LpsApiClient();

  /// Sends sign up request and returns [RemoteSignUpResponse] containing user data
  /// or throws [AuthorizationException] if cannot sign up on server by any reason.
  Future<RemoteSignUpResponse> signUp(RemoteSignUpData data);

  /// Gets a list of city requests
  Future<List<CityRequest>> getCityRequests();

  /// Sends a new city request
  Future<void> sendCityRequest(SendCityRequest request);
}
