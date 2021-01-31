package ru.aleshi.letsplaycities

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred

/**
 * Wraps the parameters of onActivityResult
 *
 * @property resultCode the result code returned from the activity.
 * @property data the optional intent returned from the activity.
 */
data class ActivityResult(
        val resultCode: Int,
        val data: Intent?
)

/**
 * Activity that can launch intents and await for its completion with suspending functions
 */
abstract class BaseAsyncActivity : FlutterActivity() {

    private var currentCode = 0
    private val resultByCode = mutableMapOf<Int, CompletableDeferred<ActivityResult?>>()

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        resultByCode[requestCode]?.let { deferred ->
            deferred.complete(ActivityResult(resultCode, data))
            resultByCode.remove(requestCode)
        } ?: run {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    /**
     * Launches the intent allowing to process the result using await()
     *
     * @param intent the intent to be launched.
     * @return result retrieved from `startActivityForResult` or `null` when no suitable activity
     * for given [intent].
     */
    fun launchIntentAsync(intent: Intent): Deferred<ActivityResult?> {
        val activityResult = CompletableDeferred<ActivityResult?>()

        if (intent.resolveActivity(packageManager) != null) {
            val resultCode = currentCode++
            resultByCode[resultCode] = activityResult
            startActivityForResult(intent, resultCode)
        } else {
            activityResult.complete(null)
        }
        return activityResult
    }

}