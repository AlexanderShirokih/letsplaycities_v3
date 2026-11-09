package ru.aleshi.letsplaycities

import android.content.Intent
import androidx.core.content.FileProvider
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import ru.aleshi.letsplaycities.gameservices.GameServices
import java.io.File

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
        MethodChannel(messenger, SHARING_CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "share_text" -> {
                    shareText(call.argument("text"))
                    result.success(null)
                }
                "share_image" -> {
                    shareImage(call.argument("path"), call.argument("text"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        authenticationManager = AuthenticationManager(messenger, this, lifecycleScope)
        gameServices = GameServices(messenger, this, lifecycleScope)

        NetworkManager(messenger, this)
    }

    private fun shareText(text: String?) {
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "text/plain"
        intent.putExtra(Intent.EXTRA_TEXT, text)
        val chooser = Intent.createChooser(intent, getString(R.string.share_with))
        if (chooser.resolveActivity(packageManager) != null) startActivity(chooser)
    }

    private fun shareImage(path: String?, text: String?) {
        if (path == null) return

        // The picture lives in the cache dir, which the file provider exposes
        val uri = FileProvider.getUriForFile(this, "$packageName.share", File(path))
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "image/png"
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.putExtra(Intent.EXTRA_TEXT, text)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val chooser = Intent.createChooser(intent, getString(R.string.share_with))
        if (chooser.resolveActivity(packageManager) != null) startActivity(chooser)
    }

    companion object {
        private const val SHARING_CHANNEL = "ru.aleshi.letsplaycities/share"
    }
}