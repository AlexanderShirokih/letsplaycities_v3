package ru.aleshi.letsplaycities.social

import com.google.android.gms.auth.api.Auth
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.games.Games
import ru.aleshi.letsplaycities.BaseAsyncActivity
import ru.aleshi.letsplaycities.R
import ru.aleshi.letsplaycities.social.GoogleServicesExt.await

class GoogleAuthorizationHelper(private val activity: BaseAsyncActivity) {

    /**
     * Launches signOut task and awaits for it completion
     */
    suspend fun signOut() {
        val options = buildSignInOptions()
        val client = GoogleSignIn.getClient(activity, options)
        client.signOut().await()
    }

    /**
     * Starts sign in flow. If last signed account is available it will returned,
     * otherwise silent sign in flow will started, and if no way to login from silent mode
     * sign in activity will launched and then result from it will returned.
     * @return [GoogleSignInAccount] if sign in successful.
     * @throws [AuthorizationException] if sign in cancelled or failed
     */
    suspend fun signIn(): GoogleSignInAccount {
        val options = buildSignInOptions()

        val account: GoogleSignInAccount =
                GoogleSignIn.getAccountForExtension(activity, Games.GamesOptions.builder().build())

        if (GoogleSignIn.hasPermissions(account, *options.scopeArray)) {
            return account
        } else {
            // Haven't been signed-in before. Try the silent sign-in first.
            val signInClient = GoogleSignIn.getClient(activity, options)
            try {
                return signInClient.silentSignIn().await()
            } catch (e: ApiException) {
                e.printStackTrace()

                // We can't silently sign in, so try to sign in implicitly
                val data = activity.launchIntentAsync(signInClient.signInIntent).await()

                return if (data != null) {
                    val result = Auth.GoogleSignInApi.getSignInResultFromIntent(data.data)
                            ?: throw AuthorizationException(
                                    errorCode = ANOTHER_ERROR,
                                    description = activity.getString(R.string.no_play_services)
                            )

                    if (result.isSuccess) {
                        result.signInAccount!!
                    } else {
                        val error = result.status.statusMessage
                                ?: "Authentication error: ${
                                    CommonStatusCodes.getStatusCodeString(
                                            result.status.statusCode
                                    )
                                }"
                        throw AuthorizationException(errorCode = AUTH_FAILED, description = error)
                    }
                } else {
                    throw AuthorizationException(
                            errorCode = ANOTHER_ERROR,
                            description = activity.getString(R.string.no_game_services)
                    )
                }
            }
        }
    }

    private fun buildSignInOptions() = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_GAMES_SIGN_IN)
            .requestServerAuthCode(activity.getString(R.string.default_web_client_id))
            .requestId().requestProfile().build()
}