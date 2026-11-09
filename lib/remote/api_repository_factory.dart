import 'dart:async';

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
  /// Server that receives the requests and serves the pictures.
  final AppConfig serverConfig;

  /// Shared by every repository that this factory builds.
  final ApiRepositoryCacheHolder cache;

  /// Token of the user that the requests act as. The Dio from
  /// [_createDio] signs the requests with it.
  final TokenStore tokens;

  final Dio Function(AppConfig, TokenStore) _createDio;

  final _tokenDrops = StreamController<void>.broadcast();

  /// Builds clients for the server at [serverConfig], which also serves the
  /// pictures.
  ApiRepositoryFactory(
    this.serverConfig,
    this.cache,
    this.tokens,
    this._createDio,
  );

  /// Builds clients for the main server at [config]. When the server rejects
  /// the stored token, the token and the cache are dropped and [tokenDrops]
  /// emits. [onError] gets the errors of dropping the token.
  factory ApiRepositoryFactory.main(
    AppConfig config,
    TokenStore tokens, {
    required void Function(Object error, StackTrace stackTrace) onError,
  }) {
    late final ApiRepositoryFactory repositories;

    return repositories = ApiRepositoryFactory(
      config,
      ApiRepositoryCacheHolder(),
      tokens,
      (config, tokens) => createApiDio(
        config,
        tokens,
        onSignedOut: repositories.onTokenDropped,
        onError: onError,
      ),
    );
  }

  /// Emits each time the server refused the stored token and it was dropped
  Stream<void> get tokenDrops => _tokenDrops.stream;

  /// The server refused the stored token and it was dropped: forgets the
  /// data of the user and tells [tokenDrops]
  void onTokenDropped() {
    cache.clear();
    _tokenDrops.add(null);
  }

  /// Repository that acts as the signed-in user
  ApiRepository forUser() {
    final dio = _createDio(serverConfig, tokens);
    return ApiRepository(SocialApi(dio), cache, serverConfig, dio);
  }

  /// Client of the city requests that acts as the signed-in
  /// user.
  LpsApiClient clientFor() =>
      RemoteLpsApiClient(_createDio(serverConfig, tokens), tokens);

  /// Dio that sends the requests to [serverConfig] as the signed-in user.
  Dio dio() => _createDio(serverConfig, tokens);
}
