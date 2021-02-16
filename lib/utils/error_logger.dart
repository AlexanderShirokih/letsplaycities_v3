/// Service used to log errors and important messages for debugging purposes
abstract class ErrorLogger {
  /// Sends log message to log system
  void log(String message);

  /// Logs an error to logging system
  void error(Object error, StackTrace stackTrace);
}

/// Simple implementation which just prints log messages to console
class SimpleErrorLogger implements ErrorLogger {
  @override
  void error(Object error, StackTrace stackTrace) =>
      print('ERROR: $error\nSTACK TRACE:\n$stackTrace');

  @override
  void log(String message) => print(message);
}
