package ru.aleshi.letsplaycities.gameservices

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import ru.aleshi.letsplaycities.BaseAsyncActivity
import ru.aleshi.letsplaycities.social.Achievement
import ru.aleshi.letsplaycities.social.AuthorizationException
import ru.aleshi.letsplaycities.social.GoogleAuthorizationHelper
import ru.aleshi.letsplaycities.social.GoogleGameServicesHelper

class GameServices(binaryMessenger: BinaryMessenger, activity: Activity, scope: CoroutineScope) {

    private val gameServicesHelper: GoogleGameServicesHelper
    private val gameServicesChannel = "ru.aleshi.letsplaycities/game_services"

    init {
        if (activity !is BaseAsyncActivity) {
            throw IllegalStateException("Only BaseAsyncActivity required!")
        }

        gameServicesHelper = GoogleGameServicesHelper(GoogleAuthorizationHelper(activity), activity)

        MethodChannel(binaryMessenger, gameServicesChannel).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            scope.launch {
                try {
                    when (call.method) {
                        "showAchievementsIntent" -> {
                            gameServicesHelper.showAchievementsIntent()
                            result.success(null)
                        }
                        "showLeaderboardIntent" -> {
                            gameServicesHelper.showLeaderboardIntent()
                            result.success(null)
                        }
                        "submitScore" -> {
                            val score = call.argument<Int>("score")
                            if (score == null) {
                                result.error("Required argument  'score' is null!", null, null)
                            } else {
                                gameServicesHelper.submitScore(score)
                                result.success(null)
                            }
                        }
                        "unlockAchievement" -> {
                            val achievementName = call.argument<String>("name")
                            val incrementCount = call.argument<Int>("incrementCount")

                            if (achievementName == null || incrementCount == null) {
                                result.error("'name' and 'incrementCount' should not be null!", null, null)
                            } else {
                                try {
                                    val achievement = translateAchievement(achievementName)
                                    gameServicesHelper.unlockAchievement(achievement, incrementCount)
                                    result.success(null)
                                } catch (e: NoSuchElementException) {
                                    result.error("Unknown achievement name: $achievementName", null, null)
                                }
                            }
                        }
                    }
                } catch (ex: AuthorizationException) {
                    result.error(
                            ex.errorCode.toString(),
                            ex.description,
                            ex.stackTraceToString(),
                    )
                }
            }
        }
    }

    private fun translateAchievement(achievementName: String): Achievement =
            Achievement.values().first { it.name.equals(achievementName, ignoreCase = true) }
}