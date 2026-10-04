package my.getgroup.get_teksi

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Device location, without Google Play Services.
 *
 * The usual way to do this in Flutter is the `geolocator` plugin, whose Android
 * implementation pulls in Play Services' location library. That is fine for a
 * Play-only app and fatal here: this app's whole point is that the same APK
 * runs on a Huawei device, and CI fails the build if a single GMS class
 * descriptor appears in the dex. So the fix comes from
 * android.location.LocationManager, which has been in the platform since API 1
 * and asks Google for nothing.
 *
 * (The artifact is not named here on purpose. The CI scan greps these folders
 * for it and does not read comments, which is the correct amount of cleverness
 * for a check whose job is to notice the string appearing at all.)
 *
 * What you give up is the fused provider's sensor blending. For placing a
 * pickup pin that a rider can drag anyway, a plain GPS or network fix is
 * enough.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "get.teksi/location"
        const val DUTY_CHANNEL = "get.teksi/duty"
        const val APP_CHANNEL = "get.teksi/app"
        const val PERMISSION_REQUEST = 4821

        /** Older than this and a cached fix is a place the rider has left. */
        const val MAX_FIX_AGE_MS = 2 * 60 * 1000L

        /** Long enough for a cold GPS fix outdoors; indoors nothing helps. */
        const val FIX_TIMEOUT_MS = 9_000L
    }

    /**
     * The call waiting on the permission dialog, if any. Android delivers the
     * answer to onRequestPermissionsResult rather than to the caller, so the
     * result has to be parked somewhere until it arrives.
     */
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "current" -> onCurrentRequested(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DUTY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(
                        startDuty(call.argument("title"), call.argument("body")),
                    )
                    "stop" -> {
                        stopDuty()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" ->
                        result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Sends the user to where this app's notifications are actually switched
     * on, and answers whether there was anywhere to send them.
     *
     * Android stops offering the permission prompt once it has been refused,
     * so past that point asking again does nothing at all — silently. Without
     * a way through to Settings, a Notifications row would be a control that
     * looks like a control and is not one.
     */
    private fun openNotificationSettings(): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            // Below API 26 there is no per-app notification screen; the app
            // detail page is the nearest thing that exists.
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        }
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            // No activity to handle it. Rare, and an OEM build with the
            // Settings app locked down is exactly the sort of place it would
            // happen.
            false
        }
    }

    /**
     * Asks the OS to keep this process alive, and answers whether it agreed.
     *
     * The location permission is checked first rather than left to fail inside
     * the service. From API 34 the framework refuses a location-typed
     * foreground service without it, and the type is not decoration here: from
     * API 29 onwards it is the thing that stops Android throttling a
     * backgrounded app's location updates down to a handful an hour, which for
     * a driver a passenger is watching is the same as not reporting at all.
     */
    private fun startDuty(title: String?, body: String?): Boolean {
        if (!hasLocationPermission()) return false
        val intent = Intent(this, DutyService::class.java).apply {
            action = DutyService.ACTION_START
            putExtra(DutyService.EXTRA_TITLE, title)
            putExtra(DutyService.EXTRA_BODY, body)
        }
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (_: Exception) {
            // API 31+ refuses a foreground service started from the background,
            // which this should never be — the driver taps a switch — but a
            // race with the app being backgrounded loses the argument, and so
            // does an OEM battery manager with opinions. Answering false lets
            // Dart carry on without the guarantee rather than believing it has
            // one.
            false
        }
    }

    /**
     * The Activity is going away, and the Flutter engine with it.
     *
     * DutyService.onTaskRemoved covers the swipe-from-recents case, but not
     * backing out of the app or the system reclaiming this Activity while the
     * process lives on. Either way the thing the service exists to keep alive
     * is already gone, so the notification has to go too.
     */
    override fun onDestroy() {
        stopDuty()
        super.onDestroy()
    }

    private fun stopDuty() {
        val intent = Intent(this, DutyService::class.java).apply {
            action = DutyService.ACTION_STOP
        }
        // Through the service rather than stopService(), so it takes its
        // notification down before it goes.
        try {
            startService(intent)
        } catch (_: Exception) {
            // Nothing running to stop, or the OS will not deliver to it. Either
            // way the service ends with the process.
            stopService(Intent(this, DutyService::class.java))
        }
    }

    private fun onCurrentRequested(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            resolveLocation(result)
            return
        }
        // Only one dialog at a time. A second call while the first is waiting
        // gets null rather than stacking prompts on the rider.
        if (pendingPermissionResult != null) {
            result.success(null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            PERMISSION_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return

        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null

        val granted = grantResults.isNotEmpty() &&
            grantResults.any { it == PackageManager.PERMISSION_GRANTED }
        if (granted) resolveLocation(result) else result.success(null)
    }

    private fun hasLocationPermission(): Boolean {
        // minSdk is 23, so the framework check is available and androidx's
        // ContextCompat would only be a longer way to write this.
        val fine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        return fine == PackageManager.PERMISSION_GRANTED ||
            coarse == PackageManager.PERMISSION_GRANTED
    }

    /**
     * A recent cached fix if there is one, otherwise wait for a live one.
     *
     * Replies exactly once: [replied] guards the race between the listener
     * firing and the timeout elapsing, either of which can happen first.
     */
    private fun resolveLocation(result: MethodChannel.Result) {
        val manager = getSystemService(LOCATION_SERVICE) as? LocationManager
        if (manager == null) {
            result.success(null)
            return
        }

        freshCachedFix(manager)?.let {
            result.success(it.asChannelMap())
            return
        }

        val provider = liveProvider(manager)
        if (provider == null) {
            result.success(null)
            return
        }

        val handler = Handler(Looper.getMainLooper())
        var replied = false
        var listener: LocationListener? = null

        fun reply(location: Location?) {
            if (replied) return
            replied = true
            listener?.let { manager.removeUpdates(it) }
            result.success(location?.asChannelMap())
        }

        listener = object : LocationListener {
            override fun onLocationChanged(location: Location) = reply(location)

            // Deprecated in API 29 and abstract before it, so it has to be here
            // for the app to run on the older Huawei devices minSdk 23 targets.
            @Deprecated("Required by LocationListener below API 29")
            override fun onStatusChanged(p: String?, s: Int, e: Bundle?) = Unit

            override fun onProviderDisabled(provider: String) = reply(null)
        }

        try {
            manager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
        } catch (_: SecurityException) {
            // Permission revoked between the check and here.
            reply(null)
            return
        }
        handler.postDelayed({ reply(null) }, FIX_TIMEOUT_MS)
    }

    /** The most recent cached fix across providers, if it is recent enough. */
    private fun freshCachedFix(manager: LocationManager): Location? {
        val now = System.currentTimeMillis()
        return try {
            manager.getProviders(true)
                .mapNotNull { manager.getLastKnownLocation(it) }
                .filter { now - it.time <= MAX_FIX_AGE_MS }
                .maxByOrNull { it.time }
        } catch (_: SecurityException) {
            null
        }
    }

    /**
     * GPS first for accuracy, network second because it answers indoors. The
     * passive provider is not used: it only reports fixes some other app asked
     * for, so on a phone where nothing else is navigating it never fires.
     */
    private fun liveProvider(manager: LocationManager): String? = when {
        manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ->
            LocationManager.GPS_PROVIDER
        manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ->
            LocationManager.NETWORK_PROVIDER
        else -> null
    }

    private fun Location.asChannelMap(): Map<String, Double> =
        mapOf("lat" to latitude, "lng" to longitude)
}
