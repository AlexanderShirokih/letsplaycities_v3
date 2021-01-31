package ru.aleshi.letsplaycities.social

import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.games.AchievementsClient
import com.google.android.gms.games.Games
import com.google.android.gms.games.LeaderboardsClient
import ru.aleshi.letsplaycities.BaseAsyncActivity
import ru.aleshi.letsplaycities.R
import ru.aleshi.letsplaycities.social.GoogleServicesExt.await

/**
 * This class contains functions for work with Google SignIn and Google Game Services
 */
class GoogleGameServicesHelper(
        private val authHelper: GoogleAuthorizationHelper,
        private val activity: BaseAsyncActivity
) {

    // region Achievements and leaderboard intents
    /**
     * Starts sign in sequence if needed and shows achievements activity
     * @throws AuthorizationException if authorization requested and has failed
     */
    suspend fun showAchievementsIntent() {
        getAchievementsClient(true)
                ?.achievementsIntent?.await()
                ?.apply { activity.launchIntentAsync(this).await() }
    }

    /**
     * Starts sign in sequence if needed and shows leaderboard activity
     * @throws AuthorizationException if authorization requested and has failed
     */
    suspend fun showLeaderboardIntent() {
        getLeaderboardsClient(true)
                ?.getLeaderboardIntent(activity.getString(R.string.score_leaderboard))
                ?.await()
                ?.apply { activity.launchIntentAsync(this).await() }
    }

    private suspend fun getAchievementsClient(
            autoSignIn: Boolean
    ): AchievementsClient? {
        val account = if (autoSignIn) {
            authHelper.signIn()
        } else {
            GoogleSignIn.getLastSignedInAccount(activity)
        }

        return account?.run { Games.getAchievementsClient(activity, this) }
    }

    private suspend fun getLeaderboardsClient(
            autoSignIn: Boolean
    ): LeaderboardsClient? {
        val account = if (autoSignIn) {
            authHelper.signIn()
        } else {
            GoogleSignIn.getLastSignedInAccount(activity)
        }

        return if (account != null) {
            Games.getLeaderboardsClient(activity, account)
        } else null
    }

    // endregion

    // region Submitting and unlocking
    /**
     * Unlocks or increments achievement on play games server only if user logged in
     * @param achievement the achievement to be unlocked
     */
    fun unlockAchievement(achievement: Achievement, incrementCount: Int) {
        GoogleSignIn.getLastSignedInAccount(activity)?.apply {
            if (GoogleSignIn.hasPermissions(this, Games.SCOPE_GAMES_LITE)) {
                val client = Games.getAchievementsClient(activity, this)
                if (achievement.isIncremental) {
                    client.increment(
                            activity.getString(achievement.res),
                            incrementCount / achievement.scaleFactor
                    )
                } else {
                    client.unlock(activity.getString(achievement.res))
                }
            }
        }
    }

    /**
     * Submits score to play games server only if user logged in
     * @param score user score to be submitted
     */
    fun submitScore(score: Int) {
        GoogleSignIn.getLastSignedInAccount(activity)?.apply {
            if (GoogleSignIn.hasPermissions(this, Games.SCOPE_GAMES_LITE))
                Games.getLeaderboardsClient(activity, this)
                        .submitScore(activity.getString(R.string.score_leaderboard), score.toLong())
        }
    }

}