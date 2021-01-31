package ru.aleshi.letsplaycities.social

import android.app.Activity
import android.content.Intent

/**
 * Interface for implementing social network providers
 */
interface ISocialNetworkService {
    /**
     * Called to start authorization sequence from current activity
     *
     * @param activity current activity
     * @throws AuthorizationException if authorization failed by any reason
     */
    suspend fun onLogin(activity: Activity): SocialAccountData

    /**
     * Logs out currently logged user
     *
     * @param activity current activity
     */
    suspend fun onLogout(activity: Activity)

    /**
     * Handles authorization result
     *
     * @return `null` if activity result cannot be accepted by the social network
     */
    fun handleActivityResult(
            requestCode: Int,
            resultCode: Int,
            data: Intent?
    ): Boolean
}