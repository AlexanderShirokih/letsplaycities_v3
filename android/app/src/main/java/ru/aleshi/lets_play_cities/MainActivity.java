package ru.aleshi.lets_play_cities;

import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Android application entry point.
 * Responsible for launch flutter engine and run platform-specific plugins
 */
public class MainActivity extends FlutterActivity {
    private static final String MIGRATION_CHANNEL = "ru.aleshi.letsplaycities/sp_migration";
    private static final String FLUTTER_SHARED_PREFERENCES_NAME = "FlutterSharedPreferences";
    private static final String LEGACY_SHARED_PREFERENCES_NAME = "letsplaycities";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), MIGRATION_CHANNEL).setMethodCallHandler((call, result) -> {
            if ("migrateLegacyPreferencesFile".equals(call.method)) {
                runMigrations();
            } else {
                result.notImplemented();
            }
        });
    }

    private void runMigrations() {
        final SharedPreferences legacyPrefs = getSharedPreferences(LEGACY_SHARED_PREFERENCES_NAME, MODE_PRIVATE);
        final SharedPreferences flutterPrefs = getSharedPreferences(FLUTTER_SHARED_PREFERENCES_NAME, MODE_PRIVATE);

        MigrationHelper.runMigrationIfNeeded(legacyPrefs, flutterPrefs);
    }
}
