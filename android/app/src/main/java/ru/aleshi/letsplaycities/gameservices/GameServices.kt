package ru.aleshi.letsplaycities.gameservices

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope

class GameServices(binaryMessenger: BinaryMessenger, activity: Activity, scope: CoroutineScope) {

    private val gameServicesChannel = "ru.aleshi.letsplaycities/game_services"

    init {
        MethodChannel(binaryMessenger, gameServicesChannel).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            result.notImplemented()
            TODO("Implement Game Services")
        }
    }
}