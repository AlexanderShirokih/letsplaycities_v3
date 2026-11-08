import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

/// The text a screen shows for [error] where it shows the reason of a failed
/// sign-in.
String authorizationErrorText(Translations t, AuthorizationException error) =>
    error is AccessDeniedException ? t.errors.accessDenied : error.description;

/// The text a screen shows for [error] where it shows the error itself.
///
/// That is `toString()` of the error. An [AccessDeniedException] carries no
/// text for the player, so it gets the translated access-denied text.
///
/// An [ApiException] gets the text of the server, or the text of its code.
String errorText(Translations t, Object error) => switch (error) {
  AccessDeniedException() || UnauthorizedException() => t.errors.accessDenied,
  ApiException(:final message?) when message.isNotEmpty => message,
  ApiException(:final code) => t.online.apiErrors[code] ?? t.online.unkError,
  _ => error.toString(),
};
