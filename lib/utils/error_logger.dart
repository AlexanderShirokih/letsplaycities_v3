/// Service used to log errors and important messages for debugging purposes
abstract class ErrorLogger {
  /// Sends log message to log system
  void log(String message);

  /// Logs an error to logging system
  void error(Object error, StackTrace stackTrace);
}
