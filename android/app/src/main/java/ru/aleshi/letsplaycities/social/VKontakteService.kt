package ru.aleshi.letsplaycities.social

import android.app.Activity
import android.content.Intent
import com.vk.api.sdk.VK
import com.vk.api.sdk.VKApiCallback
import com.vk.api.sdk.auth.VKAccessToken
import com.vk.api.sdk.auth.VKAuthCallback
import com.vk.api.sdk.requests.VKRequest
import kotlinx.coroutines.CompletableDeferred
import org.json.JSONException
import org.json.JSONObject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * Provides VKontakte authorization
 */
class VKontakteService : ISocialNetworkService {

    internal class VKUser(json: JSONObject) {
        val id: Int = json.optInt("id", 0)
        val login: String = "${json.optString("first_name", "")} ${json.optString("last_name", "")}"
        val photo: String = json.optString("photo_100", "")
    }

    internal class VKUsersRequest : VKRequest<VKUser>("users.get") {

        @Throws(JSONException::class)
        override fun parse(r: JSONObject): VKUser {
            val users = r.getJSONArray("response")
            return VKUser(users.getJSONObject(0))
        }

        init {
            addParam("fields", "photo_100")
        }
    }

    private var completer: CompletableDeferred<VKAccessToken>? = null

    override suspend fun onLogin(activity: Activity): SocialAccountData {
        completer = CompletableDeferred()

        VK.login(activity)

        val token = completer!!.await()

        return createAccountData(token)
    }

    override fun onLogout() = VK.logout()

    override fun handleActitityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return VK.onActivityResult(requestCode, resultCode, data, object : VKAuthCallback {
            override fun onLogin(token: VKAccessToken) {
                completer!!.complete(token)
            }

            override fun onLoginFailed(errorCode: Int) {
                completer!!.completeExceptionally(AuthorizationException(errorCode))
            }
        })
    }

    private suspend fun createAccountData(token: VKAccessToken): SocialAccountData {
        return suspendCoroutine { continuation ->
            VK.execute(VKUsersRequest(), object : VKApiCallback<VKUser> {
                override fun fail(error: Exception) = continuation.resumeWithException(
                        AuthorizationException(
                                errorCode = 1,
                                description = error.message ?: error.toString()
                        )
                )

                override fun success(result: VKUser) {
                    continuation.resume(SocialAccountData(
                            snUID = result.id.toString(),
                            login = result.login,
                            accessToken = token.accessToken,
                            networkType = ServiceType.Vkontakte,
                            pictureUri = result.photo
                    ))
                }
            })
        }
    }
}