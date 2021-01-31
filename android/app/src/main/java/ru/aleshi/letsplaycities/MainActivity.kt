package ru.aleshi.letsplaycities

import android.content.Intent
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import ru.aleshi.letsplaycities.gameservices.GameServices

/**
 * Android application entry point.
 * Responsible for launch flutter engine and run platform-specific plugins
 */
class MainActivity : BaseAsyncActivity() {

    private var authenticationManager: AuthenticationManager? = null
    private var gameServices: GameServices? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val result = authenticationManager?.handleActivityResult(requestCode, resultCode, data)
                ?: false

        if (!result) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, MIGRATION_CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            if ("migrateLegacyPreferencesFile" == call.method) {
                runMigrations()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(messenger, SHARING_CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            if ("share_text" == call.method) {
                shareText(call.argument("text"))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        authenticationManager = AuthenticationManager(messenger, this, lifecycleScope)
        gameServices = GameServices(messenger, this, lifecycleScope)
    }

    private fun runMigrations() {
        val legacyPrefs = getSharedPreferences(LEGACY_SHARED_PREFERENCES_NAME, MODE_PRIVATE)
        val flutterPrefs = getSharedPreferences(FLUTTER_SHARED_PREFERENCES_NAME, MODE_PRIVATE)
        MigrationHelper.runMigrationIfNeeded(legacyPrefs, flutterPrefs)
    }

    private fun shareText(text: String?) {
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "text/plain"
        intent.putExtra(Intent.EXTRA_TEXT, text)
        val chooser = Intent.createChooser(intent, getString(R.string.share_with))
        if (chooser.resolveActivity(packageManager) != null) startActivity(chooser)
    }

    companion object {
        private const val MIGRATION_CHANNEL = "ru.aleshi.letsplaycities/sp_migration"
        private const val SHARING_CHANNEL = "ru.aleshi.letsplaycities/share"
        private const val FLUTTER_SHARED_PREFERENCES_NAME = "FlutterSharedPreferences"
        private const val LEGACY_SHARED_PREFERENCES_NAME = "letsplaycities"
    }
}