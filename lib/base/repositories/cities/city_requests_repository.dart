import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

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

  /// Sends request for adding a new city to the database
  /// Throws [FetchingException] on error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<void> sendAddCityRequest({
    required int newCountryCode,
    required String newCityName,
    required String reason,
  }) =>
      _client.sendCityRequest(SendCityRequest(
        newCountryCode: newCountryCode,
        newName: newCityName,
        reason: reason,
      ));

  /// Sends request for removing an existing city from the database
  /// Throws [FetchingException] on error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<void> sendRemoveRequest({
    required int oldCountryCode,
    required String oldCityName,
    required String reason,
  }) =>
      _client.sendCityRequest(SendCityRequest(
        oldCountryCode: oldCountryCode,
        oldName: oldCityName,
        reason: reason,
      ));

  /// Sends request for editing an existing city in the database
  /// Throws [FetchingException] on error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<void> sendEditRequest({
    required int newCountryCode,
    required String newCityName,
    required int oldCountryCode,
    required String oldCityName,
    required String reason,
  }) =>
      _client.sendCityRequest(SendCityRequest(
        newCountryCode: newCountryCode,
        oldCountryCode: oldCountryCode,
        newName: newCityName,
        oldName: oldCityName,
        reason: reason,
      ));
}
