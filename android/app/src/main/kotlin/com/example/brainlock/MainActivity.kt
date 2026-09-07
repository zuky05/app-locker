package com.example.brainlock

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.provider.Settings
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
            when (call.method) {
                "getOverlayInfo" -> {
                    val isLauncher = intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)

                    val isOverlay = if (isLauncher) false else intent.getBooleanExtra("isOverlay", false)
                    val isTimeout = if (isLauncher) false else intent.getBooleanExtra("isTimeout", false)
                    val deckId = intent.data?.getQueryParameter("deckId")

                    result.success(mapOf("isOverlay" to isOverlay, "isTimeout" to isTimeout, "deckId" to deckId))
                }
                "unlockApp" -> {
                    // 1. Získame presné sekundy z Flutteru (ak by niečo zlyhalo, default dáme 0)
                    val seconds = call.argument<Int>("seconds") ?: 0
    
                    // 2. Prevedieme sekundy na milisekundy pre Android
                    val gracePeriod = seconds * 1000L
    
                    // 3. Nastavíme časovač a odblokujeme
                    AppBlockerService.unlockedUntil = System.currentTimeMillis() + gracePeriod
                    AppBlockerService.instance?.scheduleReblock(gracePeriod)
    
                    finish() 
                    result.success(true)
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
                // --- TETO DVE METÓDY SÚ KĽÚČOVÉ ---
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
        handleIntent(intent)
        
        // Znovu overíme, či neklikol na ikonu počas toho, ako appka spala v pozadí
        val isLauncher = intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_LAUNCHER)
        
        val isOverlay = if (isLauncher) false else intent.getBooleanExtra("isOverlay", false)
        val isTimeout = if (isLauncher) false else intent.getBooleanExtra("isTimeout", false)
        
        methodChannel?.invokeMethod("updateOverlayInfo", mapOf("isOverlay" to isOverlay, "isTimeout" to isTimeout))
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }
    
    
    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data = intent.data

        // Ak ide o deeplink (brainlock://share?deckId=123)
        if (Intent.ACTION_VIEW == action && data != null) {
            val deckId = data.getQueryParameter("deckId")
            if (deckId != null) {
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    methodChannel?.invokeMethod("handleDeepLink", mapOf("deckId" to deckId))
                }, 200) // Krátky delay, aby sa Flutter stihol inicializovať
            }
        }
    }
}