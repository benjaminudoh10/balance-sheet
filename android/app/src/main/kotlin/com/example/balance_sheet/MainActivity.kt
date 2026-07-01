package com.benjaminudoh10.balanced

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.view.WindowManager

import androidx.wear.tiles.TileService
import android.content.ComponentName

class MainActivity: FlutterFragmentActivity() {
    private val privacyChannel = "balanced/privacy"
    private val wearChannel = "balanced/wear"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wearChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "syncWearData") {
                    val balance = call.argument<String>("balance") ?: "0.00"
                    val investments = call.argument<String>("investments") ?: "0.00"
                    val netWorth = call.argument<String>("netWorth") ?: "0.00"
                    val currency = call.argument<String>("currency") ?: "$"
                    
                    WearStorage.saveData(this, balance, investments, netWorth, currency)
                    
                    // Notify Tiles to update (only on Wear OS watch devices)
                    if (packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_WATCH)) {
                        TileService.getUpdater(this)
                            .requestUpdate(BalancedTileService::class.java)
                    }
                        
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, privacyChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAppSwitcherPrivacy" -> {
                        val enabled = call.arguments as? Boolean ?: false
                        if (enabled) {
                            window.setFlags(
                                WindowManager.LayoutParams.FLAG_SECURE,
                                WindowManager.LayoutParams.FLAG_SECURE,
                            )
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
