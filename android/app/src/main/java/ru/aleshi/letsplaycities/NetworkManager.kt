package ru.aleshi.letsplaycities

import android.app.Activity
import android.content.Context
import android.content.Context.WIFI_SERVICE
import android.content.Intent
import android.net.wifi.WifiManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles utilities functions that used for managing Wi-Fi hotspot and connections
 */
class NetworkManager(binaryMessenger: BinaryMessenger, activity: Activity) {

    private val networkUtilsChannel = "ru.aleshi.letsplaycities/network_utils"

    init {
        MethodChannel(
            binaryMessenger,
            networkUtilsChannel
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "ensureWifiConnected" -> {
                    result.success(ensureWifiConnected(activity))
                }
                else -> result.notImplemented()
            }
        }
    }

    /* Checks that wi-fi is enabled and user connected to the right network. */
    private fun ensureWifiConnected(activity: Activity): Boolean {
        if (!isWifiEnabled(activity)) {
            activity.startActivity(Intent(WifiManager.ACTION_PICK_WIFI_NETWORK))
        } else if (isWifiIPAddressValid(activity)) {
            return true
        }
        return false
    }

    private fun getWifiManager(context: Context): WifiManager {
        return context.applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
    }

    fun isWifiEnabled(context: Context): Boolean {
        return getWifiManager(context).isWifiEnabled
    }

    fun isWifiIPAddressValid(context: Context): Boolean {
        return getWifiManager(context).connectionInfo.ipAddress != 0
    }

}