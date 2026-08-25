package com.example.brainlock // <-- Nechaj si svoj, ak je iný

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent
import android.util.Log
import android.os.Handler
import android.os.Looper

class AppBlockerService : AccessibilityService() {

    // Ninjova pamäť a prístup k jeho "budíku"
    companion object {
        var unlockedUntil: Long = 0
        var currentApp: String = ""
        var instance: AppBlockerService? = null // Aby na neho mohol Flutter zakričať
    }

    // Keď sa Ninja prebudí, zapamätá si sám seba
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    // Sleduje dvere (prepínanie appiek)
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            
            if (packageName != null) {
                currentApp = packageName // Zapíšeme si, kde práve sme
                checkAndBlock(packageName) // Skontrolujeme to
            }
        }
    }

    // Hlavná vyhadzovacia funkcia
    fun checkAndBlock(packageName: String) {
        val blockedApps = listOf("com.android.chrome", "com.android.settings")

        if (blockedApps.contains(packageName)) {
            // Skontrolujeme odpustok
            if (System.currentTimeMillis() < unlockedUntil) {
                Log.d("BrainlockNinja", "Appka $packageName má priepustku.")
                return 
            }

            Log.d("BrainlockNinja", "ZACHYTENÁ ZAKÁZANÁ APPKA: $packageName! Blokujem!")

            val launchIntent = Intent(this, MainActivity::class.java)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            launchIntent.putExtra("isOverlay", true)
            
            startActivity(launchIntent)
            
        }
    }

    // TOTO JE NÁŠ BUDÍK!
    fun scheduleReblock(delayMillis: Long) {
        Handler(Looper.getMainLooper()).postDelayed({
            Log.d("BrainlockNinja", "Budík zvoní! Čas vypršal! Skúmam, kde je používateľ...")
            // Keď budík zazvoní, skontrolujeme, či je používateľ stále v zakázanej appke
            checkAndBlock(currentApp)
        }, delayMillis)
    }

    override fun onInterrupt() {}
}