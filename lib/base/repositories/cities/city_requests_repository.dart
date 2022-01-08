import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';

class CityRequestsRepository {
  final LpsApiClient _client;

  const CityRequestsRepository(this._client);

  /// Gets a list of city edit requests.
  /// Required user to be authorized.
  /// Throws [FetchingException] on error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<List<CityRequest>> getRequests() {
    return _client.getCityRequests();
  }
}
