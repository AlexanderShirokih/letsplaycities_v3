package ru.aleshi.letsplaycities

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import ru.aleshi.letsplaycities.social.*

/**
 * Handles social network authentications
 */
class AuthenticationManager(binaryMessenger: BinaryMessenger, activity: Activity, scope: CoroutineScope) {

    private val authorizationChannel = "ru.aleshi.letsplaycities/authentication"

    init {
        MethodChannel(binaryMessenger, authorizationChannel).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            if ("login" == call.method) {
                val type = ServiceType.fromString(call.argument("authType")!!)

                scope.launch {
                    try {
                        val socialAccountData = authenticate(activity, type)
                        result.success(socialAccountData.encodeToMap())
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
    }

    private val initializedNetworks = mutableMapOf<ServiceType, ISocialNetwork>()

    // Starts authentication sequence
    private suspend fun authenticate(activity: Activity, service: ServiceType): SocialAccountData {
        var network = initializedNetworks[service]
        if (network == null) {
            network = getSocialNetworkByType(service)
            initializedNetworks[service] = network
        }
        return network.onLogin(activity)
    }

    /**
     * Tries to handle activity result.
     *
     * @return instance of `SocialAccountData` if any social network retrieves data from the result.
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        for (socialNetwork in initializedNetworks.values) {
            val result = socialNetwork.handleResult(requestCode, resultCode, data)
            if (result) return result
        }
        return false
    }

    private fun getSocialNetworkByType(service: ServiceType): ISocialNetwork {
        return when (service) {
            ServiceType.Vkontakte -> VKontakte()
        }
    }
}