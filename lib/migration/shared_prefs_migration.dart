import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Starts shared preferences migration from Kotlin-edition
/// to Flutter shared_preferences
class SharedPreferencesMigration {
  static const MethodChannel prefsMigrationChannel =
      MethodChannel('ru.aleshi.letsplaycities/sp_migration');

  /// Runs old shared preferences migration in native code.
  /// Works only for Android.
  Future<void> migrateSharedPreferencesIfNeeded() async {
    if (Platform.isAndroid)
      prefsMigrationChannel.invokeMethod('migrateLegacyPreferencesFile');
  }
}
