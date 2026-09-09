package com.example.brainlock

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

class AppBlockerService : AccessibilityService() {

    private var countDownTimer: CountDownTimer? = null
    private val notificationId = 1001
    private val channelId = "brainlock_timer_channel"
    
    private val reblockHandler = Handler(Looper.getMainLooper())
    private var reblockRunnable: Runnable? = null

    companion object {
        var unlockedUntil: Long = 0
        var gracePeriodUntil: Long = 0
        var currentApp: String = ""
        var instance: AppBlockerService? = null
        var blockedApps: MutableSet<String> = mutableSetOf("com.android.chrome")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Brainlock Časovač",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun startUnlockTimerNotification(addedSeconds: Int, maxCapSeconds: Int) {
        countDownTimer?.cancel()

        gracePeriodUntil = System.currentTimeMillis() + 2500

        val currentRemaining = if (System.currentTimeMillis() < unlockedUntil) {
            ((unlockedUntil - System.currentTimeMillis()) / 1000).toInt()
        } else {
            0
        }

        // Jediná a správna deklarácia totalSeconds
        val totalSeconds = Math.min(currentRemaining + addedSeconds, maxCapSeconds)

        unlockedUntil = System.currentTimeMillis() + (totalSeconds * 1000L)
        
        scheduleReblock(totalSeconds * 1000L)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()

        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.example.brainlock.ACTION_RETEST"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("isOverlay", true)
            putExtra("isFromNotification", true) // <--- PRIDANÁ POISTKA
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        Handler(Looper.getMainLooper()).post {
            countDownTimer = object : CountDownTimer((totalSeconds * 1000).toLong(), 1000) {
                override fun onTick(millisUntilFinished: Long) {
                    val secondsLeft = (millisUntilFinished / 1000).toInt()
                    val minutes = secondsLeft / 60
                    val seconds = secondsLeft % 60
                    val timeFormatted = String.format("%02d:%02d", minutes, seconds)

                    val notification = NotificationCompat.Builder(this@AppBlockerService, channelId)
                        .setContentTitle("Brainlock: Aplikácia odomknutá")
                        .setContentText("Zostávajúci čas: $timeFormatted")
                        .setSmallIcon(android.R.drawable.ic_dialog_info)
                        .setOngoing(true)
                        .setOnlyAlertOnce(true)
                        .setPriority(NotificationCompat.PRIORITY_LOW)
                        .addAction(android.R.drawable.ic_input_add, "Pridať čas (Test)", pendingIntent)
                        .build()

                    notificationManager.notify(notificationId, notification)
                }

                override fun onFinish() {
                    notificationManager.cancel(notificationId)
                }
            }.start()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null) {
                currentApp = packageName
                checkAndBlock(packageName)
            }
        }
    }

    fun checkAndBlock(packageName: String, isTimeout: Boolean = false) {
        if (packageName == applicationContext.packageName) return

        if (System.currentTimeMillis() < gracePeriodUntil) {
            return
        }

        if (blockedApps.contains(packageName)) {
            if (System.currentTimeMillis() < unlockedUntil) {
                return 
            }
            
            countDownTimer?.cancel()
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(notificationId)

            val launchIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                
                putExtra("isOverlay", true)
                putExtra("isTimeout", isTimeout)
            }
            startActivity(launchIntent)
        }
    }

    fun scheduleReblock(delayMillis: Long) {
        reblockRunnable?.let { reblockHandler.removeCallbacks(it) }
        
        reblockRunnable = Runnable {
            checkAndBlock(currentApp, true)
        }
        
        reblockHandler.postDelayed(reblockRunnable!!, delayMillis)
    }

    override fun onDestroy() {
        countDownTimer?.cancel()
        reblockRunnable?.let { reblockHandler.removeCallbacks(it) }
        super.onDestroy()
    }

    override fun onInterrupt() {}
}