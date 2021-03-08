import 'package:lets_play_cities/data/exceptions/exceptions.dart';

/// Describes user request failure reason
enum RequestFailReason {
  /// User is not logged into account
  notLogged,

  /// Some network error happens
  networkError,

  /// User is logged in but in another account
  wrongAccount,

  /// Unexpected exception has thrown
  exception,

  /// User declined the input request
  declinedByUser,
}

/// Describes exception in GameRequest bloc
class GameRequestException extends BaseException {
  /// Game request fail reason
  final RequestFailReason failReason;

  GameRequestException(this.failReason)
      : super(message: 'Request failed: $failReason');
}
