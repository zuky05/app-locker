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
        if (call.method == "getOverlayInfo") {
            val isOverlay = intent.getBooleanExtra("isOverlay", false)
            val isTimeout = intent.getBooleanExtra("isTimeout", false)
            result.success(mapOf("isOverlay" to isOverlay, "isTimeout" to isTimeout))

        } else if (call.method == "unlockApp") {
            val minutes = call.argument<Int>("minutes") ?: 1
            val gracePeriod = minutes * 60 * 1000L
            
            AppBlockerService.unlockedUntil = System.currentTimeMillis() + gracePeriod
            AppBlockerService.instance?.scheduleReblock(gracePeriod)
            
            finish() 
            result.success(true)

        } else if (call.method == "setBlockedApps") {
            val apps = call.argument<List<String>>("apps") ?: emptyList()
            AppBlockerService.blockedApps = apps.toMutableSet()
            result.success(true)

        // --- NOVÉ METÓDY PRE PERMISIE ---
        } else if (call.method == "isAccessibilityGranted") {
            val isGranted = isAccessibilityServiceEnabled()
            result.success(isGranted)

        } else if (call.method == "openAccessibilitySettings") {
            val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(true)

        } else {
            result.notImplemented()
        }
    }
}

// Pomocná funkcia na overenie, či je AppBlockerService aktívny
private fun isAccessibilityServiceEnabled(): Boolean {
    val expectedService = "${packageName}/${AppBlockerService::class.java.canonicalName}"
    val enabledServices = android.provider.Settings.Secure.getString(
        contentResolver,
        android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
    ) ?: return false

    return enabledServices.contains(expectedService)
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