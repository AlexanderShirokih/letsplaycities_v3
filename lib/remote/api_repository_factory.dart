import 'package:dio/dio.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';

/// Builds the [LpsApiClient] and [ApiRepository] instances that send their
/// requests to one server.
class ApiRepositoryFactory {
  /// Server that receives the requests.
  final AppConfig serverConfig;

  /// Server that the picture URLs in the replies point to.
  final AppConfig _pictureConfig;

  /// Shared by every repository that this factory and its [forServer]
  /// copies build.
  final ApiRepositoryCacheHolder cache;

  final Dio Function(AppConfig) _createDio;

  /// Builds clients for the server at [config], which also serves the
  /// pictures.
  ApiRepositoryFactory(
    AppConfig config,
    ApiRepositoryCacheHolder cache,
    Dio Function(AppConfig) createDio,
  ) : this._(config, config, cache, createDio);

  ApiRepositoryFactory._(
    this.serverConfig,
    this._pictureConfig,
    this.cache,
    this._createDio,
  );

  /// A factory that sends the requests to [server] and keeps the picture
  /// URLs and the cache of this one.
  ApiRepositoryFactory forServer(AppConfig server) =>
      ApiRepositoryFactory._(server, _pictureConfig, cache, _createDio);

  /// Repository that acts as the user with [credential].
  ApiRepository forCredential(Credential credential) {
    final dio = _createDio(serverConfig);
    return ApiRepository(
      _client(dio, InstancedCredentialsProvider(credential)),
      cache,
      dio,
    );
  }

  /// Client that acts as the user with [credential].
  LpsApiClient clientFor(Credential credential) =>
      clientWith(InstancedCredentialsProvider(credential));

  /// Client that asks [credentials] for the user on every request.
  LpsApiClient clientWith(CredentialsProvider credentials) =>
      _client(_createDio(serverConfig), credentials);

  LpsApiClient _client(Dio dio, CredentialsProvider credentials) =>
      RemoteLpsApiClient(_pictureConfig, dio, credentials);
}
