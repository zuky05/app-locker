package com.example.brainlock

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

class AppBlockerService : AccessibilityService() {

    private var countDownTimer: CountDownTimer? = null
    private val notificationId = 1001
    private val channelId = "brainlock_timer_channel"
    
    private val reblockHandler = Handler(Looper.getMainLooper())
    private var reblockRunnable: Runnable? = null

    private val unlockReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_UNLOCK) {
                val seconds = intent.getIntExtra("seconds", 0)
                val maxCap = intent.getIntExtra("maxCap", 600)
                val themeColor = intent.getIntExtra("themeColor", android.graphics.Color.BLUE)
                processUnlock(seconds, maxCap, themeColor)
            }
        }
    }

    companion object {
        const val ACTION_UNLOCK = "com.example.brainlock.ACTION_UNLOCK"
        var unlockedUntil: Long = 0
        var gracePeriodUntil: Long = 0
        var currentApp: String = ""
        var instance: AppBlockerService? = null
        var blockedApps: MutableSet<String> = mutableSetOf("com.android.chrome")

        fun requestUnlock(context: Context, seconds: Int, maxCap: Int, themeColor: Int) {
            val now = System.currentTimeMillis()
            gracePeriodUntil = now + 5000L // 5s ochranná lehota zápisom priamo do pamäte

            if (instance != null) {
                instance?.processUnlock(seconds, maxCap, themeColor)
            } else {
                val intent = Intent(ACTION_UNLOCK).apply {
                    putExtra("seconds", seconds)
                    putExtra("maxCap", maxCap)
                    putExtra("themeColor", themeColor)
                    setPackage(context.packageName)
                }
                context.sendBroadcast(intent)
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        createNotificationChannel()

        // 🟢 Odstránené startForeground(), ktoré spôsobovalo sekery a ANR padanie
        val filter = IntentFilter(ACTION_UNLOCK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(unlockReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(unlockReceiver, filter)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Brainlock Časovač",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun processUnlock(addedSeconds: Int, maxCapSeconds: Int, themeColor: Int) {
        countDownTimer?.cancel()

        val now = System.currentTimeMillis()
        gracePeriodUntil = now + 5000L

        val currentRemaining = if (now < unlockedUntil) {
            ((unlockedUntil - now) / 1000).toInt()
        } else {
            0
        }

        val totalSeconds = Math.min(currentRemaining + addedSeconds, maxCapSeconds)

        if (totalSeconds > 0) {
            unlockedUntil = now + (totalSeconds * 1000L)
            scheduleReblock(totalSeconds * 1000L)

            // Zobrazenie notifikácie okamžite bez čakania na prvú sekundu časovača
            updateNotification(totalSeconds, themeColor)

            Handler(Looper.getMainLooper()).post {
                countDownTimer = object : CountDownTimer((totalSeconds * 1000).toLong(), 1000) {
                    override fun onTick(millisUntilFinished: Long) {
                        val secondsLeft = (millisUntilFinished / 1000).toInt()
                        updateNotification(secondsLeft, themeColor)
                    }

                    override fun onFinish() {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager.cancel(notificationId)
                    }
                }.start()
            }
        } else {
            unlockedUntil = 0
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(notificationId)
            goHome()
        }
    }

    private fun updateNotification(secondsLeft: Int, themeColor: Int) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()

        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.example.brainlock.ACTION_RETEST"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("isOverlay", true)
            putExtra("isFromNotification", true)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val minutes = secondsLeft / 60
        val seconds = secondsLeft % 60
        val timeFormatted = String.format("%02d:%02d", minutes, seconds)

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Brainlock: Aplikácia odomknutá")
            .setContentText("Zostávajúci čas: $timeFormatted")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setColor(themeColor)
            .setColorized(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .addAction(android.R.drawable.ic_input_add, "Pridať čas (Test)", pendingIntent)
            .build()

        notificationManager.notify(notificationId, notification)
    }

    fun goHome() {
        performGlobalAction(GLOBAL_ACTION_HOME)
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
        try {
            unregisterReceiver(unlockReceiver)
        } catch (e: Exception) {}
        countDownTimer?.cancel()
        reblockRunnable?.let { reblockHandler.removeCallbacks(it) }
        super.onDestroy()
    }

    override fun onInterrupt() {}
}