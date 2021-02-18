/// Base exception used in application codebase
class BaseException implements Exception {
  final String? message;
  final Exception? parentException;
  final StackTrace? stackTrace;

  /// Constructs new [BaseException]
  const BaseException({
    this.message,
    this.stackTrace,
    this.parentException,
  });
}
