package ru.aleshi.letsplaycities.social

import android.app.Activity
import android.content.Intent
import com.facebook.*
import com.facebook.login.LoginManager
import com.facebook.login.LoginResult
import kotlinx.coroutines.CompletableDeferred

/**
 * Handles authorization using Facebook service.
 */
class FacebookService : ISocialNetworkService {

    private var callbackManager: CallbackManager? = null
    private var completer: CompletableDeferred<AccessToken>? = null

    override suspend fun onLogin(activity: Activity): SocialAccountData {
        if (callbackManager == null) {
            callbackManager = CallbackManager.Factory.create()
            object : ProfileTracker() {
                override fun onCurrentProfileChanged(oldProfile: Profile?, currentProfile: Profile?) {
                    stopTracking()
                }
            }
        }

        completer = CompletableDeferred()

        LoginManager.getInstance()!!.apply {
            registerCallback(callbackManager!!, object : FacebookCallback<LoginResult> {
                override fun onSuccess(result: LoginResult) {

                    completer!!.complete(result.accessToken)
                }

                override fun onCancel() {
                    completer!!.completeExceptionally(AuthorizationException(
                            errorCode = CANCELLED_BY_USER,
                            description = "Cancelled"
                    ))
                }

                override fun onError(error: FacebookException) {
                    completer!!.completeExceptionally(AuthorizationException(
                            errorCode = AUTH_FAILED,
                            description = error.message ?: "No description"
                    ))
                }

            })

            logInWithReadPermissions(activity, listOf("public_profile"))
        }

        val token = completer!!.await()

        val profile = Profile.getCurrentProfile() ?: throw AuthorizationException(
                errorCode = AUTH_FAILED,
                description = "Can't get profile!"
        )

        return getSocialDataFromProfile(profile, token.token)
    }

    private fun getSocialDataFromProfile(profile: Profile, token: String): SocialAccountData {
        return SocialAccountData(
                snUID = profile.id,
                login = profile.name,
                accessToken = token,
                networkType = ServiceType.Facebook,
                pictureUri = profile.getProfilePictureUri(128, 128).toString()
        )
    }

    override fun onLogout() {
        LoginManager.getInstance()!!.logOut()
    }

    override fun handleActitityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return callbackManager?.onActivityResult(requestCode, resultCode, data) ?: false
    }

}