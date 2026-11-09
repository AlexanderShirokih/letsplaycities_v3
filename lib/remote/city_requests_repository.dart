import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
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
  /// Returns the created request.
  /// Throws [ApiException] when the server refuses the request
  /// (`bad_reason`, `bad_request`, `too_many_requests`).
  /// Throws [FetchingException] on a network error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<CityRequest> sendAddCityRequest({
    required int newCountryCode,
    required String newCityName,
    required String reason,
  }) => _client.sendCityRequest(
    SendCityRequest(
      newCountryCode: newCountryCode,
      newName: newCityName,
      reason: reason,
    ),
  );

  /// Sends request for removing an existing city from the database
  /// Returns the created request.
  /// Throws [ApiException] when the server refuses the request
  /// (`bad_reason`, `bad_request`, `too_many_requests`).
  /// Throws [FetchingException] on a network error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<CityRequest> sendRemoveRequest({
    required int oldCountryCode,
    required String oldCityName,
    required String reason,
  }) => _client.sendCityRequest(
    SendCityRequest(
      oldCountryCode: oldCountryCode,
      oldName: oldCityName,
      reason: reason,
    ),
  );

  /// Sends request for editing an existing city in the database
  /// Returns the created request.
  /// Throws [ApiException] when the server refuses the request
  /// (`bad_reason`, `bad_request`, `too_many_requests`).
  /// Throws [FetchingException] on a network error
  /// Throws [NotAuthorizedException] if user is not authorized
  Future<CityRequest> sendEditRequest({
    required int newCountryCode,
    required String newCityName,
    required int oldCountryCode,
    required String oldCityName,
    required String reason,
  }) => _client.sendCityRequest(
    SendCityRequest(
      newCountryCode: newCountryCode,
      oldCountryCode: oldCountryCode,
      newName: newCityName,
      oldName: oldCityName,
      reason: reason,
    ),
  );
}
