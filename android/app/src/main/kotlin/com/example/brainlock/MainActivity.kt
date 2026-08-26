package com.example.brainlock // <-- Nechaj si svoj, ak je iný

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "brainlock.channel"
    private var methodChannel: MethodChannel? = null

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            // TOTO SME ZMENILI: Posielame obe informácie naraz
            if (call.method == "getOverlayInfo") {
                val isOverlay = intent.getBooleanExtra("isOverlay", false)
                val isTimeout = intent.getBooleanExtra("isTimeout", false)
                
                result.success(mapOf("isOverlay" to isOverlay, "isTimeout" to isTimeout))
                
            } else if (call.method == "unlockApp") {
                
                // Kotlin si vytiahne číslo z Flutteru (ak nepríde, dá 1 minútu)
                val minutes = call.argument<Int>("minutes") ?: 1
                val gracePeriod = minutes * 60 * 1000L // Prepočet na milisekundy
                
                AppBlockerService.unlockedUntil = System.currentTimeMillis() + gracePeriod
                AppBlockerService.instance?.scheduleReblock(gracePeriod)
                
                finish() 
                result.success(true)
                
            } else if (call.method == "setBlockedApps") {
                val apps = call.argument<List<String>>("apps") ?: emptyList()
                AppBlockerService.blockedApps = apps.toMutableSet()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) 
        val isOverlay = intent.getBooleanExtra("isOverlay", false)
        val isTimeout = intent.getBooleanExtra("isTimeout", false) // TOTO JE NOVÉ
        
        // Zmenili sme názov funkcie a posielame mapu
        methodChannel?.invokeMethod("updateOverlayInfo", mapOf("isOverlay" to isOverlay, "isTimeout" to isTimeout))
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }
}