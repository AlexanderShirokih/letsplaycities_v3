import 'user.dart';

/// Throws when [User] has no word and skips the move.
class SkipMoveException implements Exception {
  final User target;

  SkipMoveException(this.target);
}
