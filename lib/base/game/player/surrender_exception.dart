import 'user.dart';

/// Throws when [User] surrenders.
class SurrenderException implements Exception {
  final User target;
  final bool byDisconnection;

  SurrenderException(this.target, this.byDisconnection);
}
