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
        var blockedApps: MutableSet<String> = mutableSetOf("com.android.chrome")
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
    // 1. ZMENA: Pridali sme parameter isTimeout (predvolene je false)
    fun checkAndBlock(packageName: String, isTimeout: Boolean = false) {
        // Ignorujeme našu vlastnú appku
        if (packageName == applicationContext.packageName) return

        // Kontrolujeme náš dynamický zoznam
        if (blockedApps.contains(packageName)) {
            if (System.currentTimeMillis() < unlockedUntil) {
                var penis: Long = (unlockedUntil - System.currentTimeMillis()) / 60000 
                Log.d("BrainlockNinja", "Appka $packageName má priepustku do $penis")
                return 
            }

            Log.d("BrainlockNinja", "ZACHYTENÁ ZAKÁZANÁ APPKA: $packageName! Blokujem!")
            
            val launchIntent = Intent(this, MainActivity::class.java)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            
            // Posielame do Flutteru OBA signály
            launchIntent.putExtra("isOverlay", true)
            launchIntent.putExtra("isTimeout", isTimeout) // TOTO JE NOVÉ
            
            startActivity(launchIntent)
        }
    }

    // 2. ZMENA: Keď zvoní budík, povieme, že je to Timeout (true)
    fun scheduleReblock(delayMillis: Long) {
        Handler(Looper.getMainLooper()).postDelayed({
            Log.d("BrainlockNinja", "Budík zvoní! Čas vypršal! Skúmam, kde je používateľ...")
            checkAndBlock(currentApp, true) // Posielame TRUE pre Timeout!
        }, delayMillis)
    }

    override fun onInterrupt() {}
}