import 'package:dio/dio.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';

/// Returns a Dio for the REST API of [config] that signs the requests with
/// the token of [tokens].
///
/// When the server rejects a token that is still the stored one, the token
/// is dropped and [onSignedOut] runs. A late answer to a request sent with
/// an older token keeps the token of a newer sign-in. [onError] gets the
/// errors of dropping the token.
Dio createApiDio(
  AppConfig config,
  TokenStore tokens, {
  void Function()? onSignedOut,
  required void Function(Object error, StackTrace stackTrace) onError,
}) {
  Future<void> dropToken(String? sentToken) => dropSentToken(
    tokens,
    sentToken,
    onSignedOut: onSignedOut,
    onError: onError,
  );

  return Dio(
    BaseOptions(
      baseUrl: config.restBaseUrl,
      connectTimeout: const Duration(milliseconds: 8000),
      receiveTimeout: const Duration(milliseconds: 5000),
    ),
  )..interceptors.add(ApiInterceptor(tokens, onUnauthorized: dropToken));
}

/// Drops the token of [tokens] that the server rejected, if it is still
/// [sentToken], and runs [onSignedOut]. A late answer to a request sent with
/// an older token keeps the token of a newer sign-in. [onError] gets the
/// errors of dropping the token.
Future<void> dropSentToken(
  TokenStore tokens,
  String? sentToken, {
  void Function()? onSignedOut,
  required void Function(Object error, StackTrace stackTrace) onError,
}) async {
  try {
    final current = await tokens.read();
    if (sentToken == null || current != sentToken) return;

    await tokens.clear();
    onSignedOut?.call();
  } catch (e, s) {
    onError(e, s);
  }
}
