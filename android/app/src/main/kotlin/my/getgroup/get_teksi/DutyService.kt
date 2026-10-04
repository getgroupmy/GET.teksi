package my.getgroup.get_teksi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

/**
 * Keeps the app alive while a driver is on duty.
 *
 * Android is entitled to freeze a backgrounded process, and does: no position
 * reported, no realtime event received, no notification raised. The driver
 * still looks online to the server. On the devices this app cares about most —
 * the ones with no Play Services, where OEM battery managers are at their most
 * enthusiastic — that can happen within a minute of leaving the app.
 *
 * A foreground service is the platform's sanctioned exemption, and the price is
 * an ongoing notification the user cannot dismiss. That price is the right way
 * round here: a driver being followed by their employer's app should be able to
 * see that it is running, and the notification is the way back into the app to
 * stop it.
 *
 * Started and stopped from [MainActivity] over a method channel, so the
 * decision about *when* stays in Dart with the rest of the duty logic.
 */
class DutyService : Service() {

    companion object {
        const val ACTION_START = "my.getgroup.get_teksi.DUTY_START"
        const val ACTION_STOP = "my.getgroup.get_teksi.DUTY_STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        /**
         * Its own channel, separate from ride alerts, and deliberately low
         * importance: this notification is a status light, not news. Sharing
         * the ride channel would mean a driver who silenced the permanent
         * notification also silenced the offer that pays for their evening.
         */
        private const val CHANNEL_ID = "get_teksi_duty"
        private const val CHANNEL_NAME = "On duty"
        private const val CHANNEL_DESCRIPTION =
            "Shown while you are online and taking orders."

        /** Any non-zero id; the service owns the only notification it posts. */
        private const val NOTIFICATION_ID = 1971
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra(EXTRA_TITLE) ?: CHANNEL_NAME
        val body = intent?.getStringExtra(EXTRA_BODY) ?: CHANNEL_DESCRIPTION
        // Also the update path: starting an already-running service delivers
        // another onStartCommand, which is how a language change reaches the
        // notification without stopping and restarting the service.
        try {
            startForeground(NOTIFICATION_ID, buildNotification(title, body))
        } catch (_: Exception) {
            // API 34 refuses to start a location-typed service without the
            // location permission, and every version can refuse for reasons of
            // its own. MainActivity checks the permission before asking, so
            // reaching here means the OS said no to something it had already
            // allowed — a race with the user revoking it, most likely. Better
            // to have no service than a notification promising one.
            stopSelf()
            return START_NOT_STICKY
        }

        // Not sticky. If Android kills this anyway, the driver's phone has run
        // out of room for us and silently restarting into a service with no
        // Flutter engine behind it would produce a notification claiming the
        // app is working when nothing is.
        return START_NOT_STICKY
    }

    // The channel-less Notification.Builder is deprecated and still the only
    // one that exists below API 26, which minSdk 23 keeps in range — that is
    // where a fair number of the Huawei devices this app targets live.
    @Suppress("DEPRECATION")
    private fun buildNotification(title: String, body: String): Notification {
        ensureChannel()

        // Reopens the app rather than launching a second copy of it: the
        // Activity is almost certainly still alive behind this, which is the
        // entire point of the service.
        val open = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setContentTitle(title)
            .setContentText(body)
            // The launcher icon, which the manifest also names, so the release
            // build's resource shrinker keeps it. A notification whose icon
            // resource is missing does not show at all.
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pending)
            .setOngoing(true)
            .setShowWhen(false)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = CHANNEL_DESCRIPTION
            setShowBadge(false)
        }
        // Creating a channel that already exists updates its label and leaves
        // the user's own importance choice alone, which is the behaviour we
        // want on every start.
        manager.createNotificationChannel(channel)
    }

    /**
     * The user swiped the app out of the recents list.
     *
     * That destroys the Activity and with it the Flutter engine, which is where
     * every part of this app that does anything lives. The service would happily
     * carry on holding up a notification saying the driver is online and taking
     * orders, with nothing behind it able to receive one. A notification that
     * lies is worse than no notification.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        stopForegroundCompat()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    // Same again for the boolean stopForeground, replaced in API 24.
    @Suppress("DEPRECATION")
    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
    }
}
