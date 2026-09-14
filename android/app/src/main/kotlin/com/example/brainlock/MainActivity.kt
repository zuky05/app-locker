package com.example.brainlock

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings

// 1. ZMENA: Importujeme FlutterFragmentActivity namiesto FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 2. ZMENA: MainActivity teraz dedí z FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {
    
    private val CHANNEL = "brainlock.channel"
    private var methodChannel: MethodChannel? = null
    private var isUnlocking = false

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getOverlayInfo" -> {
                    if (isUnlocking) {
                        result.success(mapOf("isOverlay" to false, "isTimeout" to false, "isFromNotification" to false, "deckId" to null))
                        return@setMethodCallHandler
                    }

                    val isLauncher = intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)

                    // SPRÁVNE PREČÍTANIE PRI ŠTARTE
                    val isFromNotif = intent.getBooleanExtra("isFromNotification", false) || intent.action == "com.example.brainlock.ACTION_RETEST"
                    val isOverlay = if (isLauncher) false else (intent.getBooleanExtra("isOverlay", false) || isFromNotif)
                    val isTimeout = if (isLauncher) false else intent.getBooleanExtra("isTimeout", false)
                    val deckId = intent.data?.getQueryParameter("deckId")

                    intent.removeExtra("isOverlay")
                    intent.removeExtra("isTimeout")
                    intent.removeExtra("isFromNotification")
                    if (intent.action == "com.example.brainlock.ACTION_RETEST") {
                        intent.action = null
                    }

                    result.success(mapOf(
                        "isOverlay" to isOverlay, 
                        "isTimeout" to isTimeout, 
                        "isFromNotification" to isFromNotif,
                        "deckId" to deckId
                    ))
                }
                "unlockApp" -> {
                    val seconds = call.argument<Int>("seconds") ?: 0
                    val maxCap = call.argument<Int>("maxCap") ?: 600
                    // 🟢 Zachytíme farbu témy poslanú z Flutteru (s predvolenou modrou ako zálohou)
                    val themeColor = call.argument<Int>("themeColor") ?: android.graphics.Color.BLUE
                    
                    isUnlocking = true
                    
                    intent.removeExtra("isOverlay")
                    intent.removeExtra("isTimeout")
                    intent.removeExtra("isFromNotification")
                    intent.action = null

                    // 🟢 Odšleme farbu do notifikačnej služby
                    AppBlockerService.instance?.startUnlockTimerNotification(seconds, maxCap, themeColor)
                    
                    finish() 
                    result.success(true)

                    Handler(Looper.getMainLooper()).postDelayed({
                        isUnlocking = false
                    }, 2000)
                }
                "setBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    AppBlockerService.blockedApps = apps.toMutableSet()
                    result.success(true)
                }
                "isAccessibilityGranted" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "isOverlayGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedService = ComponentName(this, AppBlockerService::class.java).flattenToString()
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(expectedService) == true
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) 
        
        if (isUnlocking) return

        handleIntent(intent)

        val isLauncher = intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)
        
        // SPRÁVNE PREČÍTANIE PRI BEŽIACEJ APLIKÁCII
        val isFromNotif = intent.getBooleanExtra("isFromNotification", false) || intent.action == "com.example.brainlock.ACTION_RETEST"
        val isOverlay = if (isLauncher) false else (intent.getBooleanExtra("isOverlay", false) || isFromNotif)
        val isTimeout = if (isLauncher) false else intent.getBooleanExtra("isTimeout", false)
        
        intent.removeExtra("isOverlay")
        intent.removeExtra("isTimeout")
        intent.removeExtra("isFromNotification")
        
        if (intent.action == "com.example.brainlock.ACTION_RETEST") {
            intent.action = null
        }

        methodChannel?.invokeMethod("updateOverlayInfo", mapOf(
            "isOverlay" to isOverlay, 
            "isTimeout" to isTimeout, 
            "isFromNotification" to isFromNotif
        ))
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }
    
    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data = intent.data

        if (Intent.ACTION_VIEW == action && data != null) {
            val deckId = data.getQueryParameter("deckId")
            if (deckId != null) {
                Handler(Looper.getMainLooper()).postDelayed({
                    methodChannel?.invokeMethod("handleDeepLink", mapOf("deckId" to deckId))
                }, 200)
            }
        }
    }
}