package ru.aleshi.letsplaycities.social

import android.app.Activity
import android.content.Intent
import ru.aleshi.letsplaycities.BaseAsyncActivity
import ru.aleshi.letsplaycities.R

/**
 * Implements Google SignIn
 */
class GoogleService : ISocialNetworkService {

    override suspend fun onLogin(activity: Activity): SocialAccountData {
        val authorizationHelper = GoogleAuthorizationHelper(requireBaseActivity(activity))

        val account = authorizationHelper.signIn()

        val isAllRequestedDataPresent =
                account.id != null && account.serverAuthCode != null && account.displayName != null && account.photoUrl != null

        if (isAllRequestedDataPresent) {
            return SocialAccountData(
                    snUID = account.id!!,
                    login = account.displayName!!,
                    accessToken = account.serverAuthCode!!,
                    networkType = ServiceType.Google,
                    pictureUri = account.photoUrl!!.toString()
            )
        } else {
            authorizationHelper.signOut()
            throw AuthorizationException(errorCode = ANOTHER_ERROR, description = activity.getString(R.string.not_all_requested_data_received))
        }
    }

    override suspend fun onLogout(activity: Activity) {
        GoogleAuthorizationHelper(requireBaseActivity(activity)).signOut()
    }

    private fun requireBaseActivity(activity: Activity) : BaseAsyncActivity {
        if (activity !is BaseAsyncActivity) {
            throw IllegalStateException("Only BaseAsyncActivity required!")
        }
        return activity
    }

    override fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) = false

}