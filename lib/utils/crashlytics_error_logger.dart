import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:lets_play_cities/utils/error_logger.dart';

class CrashlyticsErrorLogger implements ErrorLogger {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  @override
  void error(Object error, StackTrace stackTrace) =>
      _crashlytics.recordError(error, stackTrace);

  @override
  void log(String message) => _crashlytics.log(message);
}
