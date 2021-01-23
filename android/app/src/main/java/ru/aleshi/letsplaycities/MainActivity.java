package ru.aleshi.letsplaycities;

import android.content.Intent;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/**
 * Android application entry point.
 * Responsible for launch flutter engine and run platform-specific plugins
 */
public class MainActivity extends FlutterActivity {
    private static final String MIGRATION_CHANNEL = "ru.aleshi.letsplaycities/sp_migration";
    private static final String SHARING_CHANNEL = "ru.aleshi.letsplaycities/share";
    private static final String FLUTTER_SHARED_PREFERENCES_NAME = "FlutterSharedPreferences";
    private static final String LEGACY_SHARED_PREFERENCES_NAME = "letsplaycities";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();

        new MethodChannel(messenger, MIGRATION_CHANNEL).setMethodCallHandler((call, result) -> {
            if ("migrateLegacyPreferencesFile".equals(call.method)) {
                runMigrations();
                result.success(null);
            } else {
                result.notImplemented();
            }
        });

        new MethodChannel(messenger, SHARING_CHANNEL).setMethodCallHandler((call, result) -> {
            if ("share_text".equals(call.method)) {
                shareText(call.argument("text"));
                result.success(null);
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

    private void shareText(String text) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_TEXT, text);

        Intent chooser = Intent.createChooser(intent, getString(R.string.share_with));
        if (chooser.resolveActivity(getPackageManager()) != null)
            startActivity(chooser);
    }
}
