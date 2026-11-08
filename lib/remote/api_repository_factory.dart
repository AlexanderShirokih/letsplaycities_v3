import 'package:dio/dio.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/client/api_dio.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/client/social_api.dart';

/// Builds the [LpsApiClient] and [ApiRepository] instances that send their
/// requests to one server as the user whose token the [tokens] hold.
class ApiRepositoryFactory {
  /// Server that receives the requests.
  final AppConfig serverConfig;

  /// The main server: the picture URLs in the replies point to it, also
  /// when [serverConfig] is a LAN server.
  final AppConfig pictureConfig;

  /// Shared by every repository that this factory and its [forServer]
  /// copies build.
  final ApiRepositoryCacheHolder cache;

  /// Token of the user that the requests act as. The Dio from
  /// [_createDio] signs the requests with it.
  final TokenStore tokens;

  final Dio Function(AppConfig, TokenStore) _createDio;

  /// Builds clients for the server at [config], which also serves the
  /// pictures.
  ApiRepositoryFactory(
    AppConfig config,
    ApiRepositoryCacheHolder cache,
    TokenStore tokens,
    Dio Function(AppConfig, TokenStore) createDio,
  ) : this._(config, config, cache, tokens, createDio);

  /// Builds clients for the main server at [config]. When the server rejects
  /// the stored token, the token and the cache are dropped. [onError] gets
  /// the errors of dropping the token.
  factory ApiRepositoryFactory.main(
    AppConfig config,
    TokenStore tokens, {
    required void Function(Object error, StackTrace stackTrace) onError,
  }) {
    final cache = ApiRepositoryCacheHolder();

    return ApiRepositoryFactory(
      config,
      cache,
      tokens,
      (config, tokens) => createApiDio(
        config,
        tokens,
        onSignedOut: cache.clear,
        onError: onError,
      ),
    );
  }

  ApiRepositoryFactory._(
    this.serverConfig,
    this.pictureConfig,
    this.cache,
    this.tokens,
    this._createDio,
  );

  /// A factory that sends the requests to [server] and keeps the picture
  /// URLs and the cache of this one. [tokens] belong to that server.
  ApiRepositoryFactory forServer(AppConfig server, TokenStore tokens) =>
      ApiRepositoryFactory._(server, pictureConfig, cache, tokens, _createDio);

  /// Repository that acts as the signed-in user
  ApiRepository forUser() {
    final dio = _createDio(serverConfig, tokens);
    return ApiRepository(SocialApi(dio), cache, pictureConfig, dio);
  }

  /// Client of the sign-up and the city requests that acts as the signed-in
  /// user.
  LpsApiClient clientFor() =>
      RemoteLpsApiClient(_createDio(serverConfig, tokens), tokens);

  /// Dio that sends the requests to [serverConfig] as the signed-in user.
  Dio dio() => _createDio(serverConfig, tokens);
}
