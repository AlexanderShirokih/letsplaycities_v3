package ru.aleshi.letsplaycities.social

import android.app.Activity
import android.content.Intent
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import org.json.JSONObject
import ru.ok.android.sdk.Odnoklassniki
import ru.ok.android.sdk.OkAuthListener
import ru.ok.android.sdk.OkRequestMode
import ru.ok.android.sdk.util.OkAuthType
import ru.ok.android.sdk.util.OkScope

/**
 * Provides authorization for ok.ru social network
 */
class OdnoklassnikiService : ISocialNetworkService {

    companion object {
        private const val REDIRECT_URI = "okauth://ok1267998976"
    }

    private var odnoklassniki: Odnoklassniki? = null
    private var completer: CompletableDeferred<String>? = null

    private fun getOk(activity: Activity): Odnoklassniki {
        odnoklassniki = if (Odnoklassniki.hasInstance()) {
            Odnoklassniki.of(activity)
        } else {
            Odnoklassniki.createInstance(
                    activity,
                    "1267998976",
                    "CBACCFJMEBABABABA"
            )
        }
        return odnoklassniki!!
    }

    override suspend fun onLogin(activity: Activity): SocialAccountData {
        val odnoklassniki = getOk(activity)

        completer = CompletableDeferred()

        odnoklassniki.requestAuthorization(
                activity,
                REDIRECT_URI,
                OkAuthType.ANY,
                OkScope.VALUABLE_ACCESS,
                OkScope.LONG_ACCESS_TOKEN
        )

        val accessToken = completer!!.await()

        return getAccountInfo(accessToken)
    }

    override suspend fun onLogout(activity: Activity) {
        getOk(activity).clearTokens()
    }

    override fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val ok = odnoklassniki ?: return false

        if (ok.isActivityRequestOAuth(requestCode)) {
            // Process OAUTH sign-in response
            ok.onAuthActivityResult(requestCode,
                    resultCode,
                    data,
                    object : OkAuthListener {
                        override fun onCancel(error: String?) {
                            completer!!.completeExceptionally(AuthorizationException(
                                    errorCode = CANCELLED_BY_USER,
                                    description = error ?: "Cancelled"
                            ))
                        }

                        override fun onError(error: String?) {
                            completer!!.completeExceptionally(AuthorizationException(
                                    errorCode = AUTH_FAILED,
                                    description = error ?: "No description"
                            ))
                        }

                        override fun onSuccess(json: JSONObject) {
                            completer!!.complete(json.getString("access_token"))
                        }
                    })
        }
        return false
    }

    private suspend fun getAccountInfo(accessToken: String): SocialAccountData = coroutineScope {
        withContext(Dispatchers.IO) {

            @Suppress("BlockingMethodInNonBlockingContext")
            val result = odnoklassniki!!.request(
                    "users.getCurrentUser",
                    null,
                    OkRequestMode.DEFAULT
            )

            if (result.isNullOrEmpty()) {
                throw AuthorizationException(AUTH_FAILED, "Auth result is empty!")
            }

            val user = JSONObject(result)
            SocialAccountData(
                    snUID = user.getString("uid"),
                    login = user.getString("name"),
                    accessToken = accessToken,
                    networkType = ServiceType.Odnoklassniki,
                    pictureUri = user.getString("pic_3")
            )
        }
    }

}