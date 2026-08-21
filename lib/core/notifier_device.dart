import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';
import 'notifier.dart';

/// The platform's own notification manager.
///
/// One channel rather than several. Splitting ride alerts from safety alerts
/// would let someone mute the ride ones and leave the app looking like it works
/// while it silently stops telling them their driver arrived, and this app has
/// nothing to say that is not worth hearing.
Notifier buildNotifier() => const _DeviceNotifier();

const _channelId = 'get_teksi_rides';
const _channelName = 'Ride updates';
const _channelDescription =
    'Offers on your order, trip progress, and safety alerts.';

/// Answered by MainActivity on Android and AppDelegate on iOS.
///
/// Not the notification plugin's own channel: sending someone to the system
/// screen where this permission is granted is a thing about the app, not about
/// notifications, and the plugin has no method for it.
const _appChannel = MethodChannel('get.teksi/app');

class _DeviceNotifier implements Notifier {
  const _DeviceNotifier();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// True once the plugin is usable. False on a platform with no
  /// implementation, which every caller treats as "stay quiet" rather than as
  /// a failure.
  Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          // The launcher icon, which the manifest also names as the app
          // icon — so the release build's resource shrinker keeps it. An icon
          // referenced only from here would be stripped, and a notification
          // whose icon resource is missing does not show at all.
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Asked for separately below, so starting the app does not throw a
          // permission dialog at someone before they have seen why it wants
          // one.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestPermission() async {
    if (!await _ensureReady()) return;
    try {
      // kIsWeb rather than another case in the switch: on the web
      // defaultTargetPlatform reports the machine the browser runs on, so a
      // phone browser is indistinguishable from a phone in here.
      if (kIsWeb) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          // Android 13+ only. Older versions grant it at install, where the
          // call is simply absent — hence the null-aware resolve rather than a
          // version check.
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
        case TargetPlatform.iOS:
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true);
        case _:
          return;
      }
    } catch (_) {
      // A refused or unavailable permission means a quieter app, not a broken
      // one. The in-app centre still has everything.
    }
  }

  @override
  Future<NotificationPermission> status() async {
    if (!await _ensureReady()) return NotificationPermission.unavailable;
    try {
      if (kIsWeb) {
        final web = _plugin
            .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin
            >();
        if (web == null) return NotificationPermission.unavailable;
        return web.permissionStatus == WebNotificationPermission.granted
            ? NotificationPermission.granted
            : NotificationPermission.denied;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          if (android == null) return NotificationPermission.unavailable;
          // Null means the platform declined to answer. Reading that as
          // granted would put an "On" in Settings with nothing behind it.
          final enabled = await android.areNotificationsEnabled();
          return enabled == true
              ? NotificationPermission.granted
              : NotificationPermission.denied;
        case TargetPlatform.iOS:
          final ios = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          if (ios == null) return NotificationPermission.unavailable;
          final options = await ios.checkPermissions();
          return options?.isEnabled == true
              ? NotificationPermission.granted
              : NotificationPermission.denied;
        case _:
          return NotificationPermission.unavailable;
      }
    } catch (_) {
      return NotificationPermission.unavailable;
    }
  }

  @override
  Future<bool> openSettings() async {
    // Nowhere to send anyone. A browser keeps this permission behind its own
    // chrome, which a page is not allowed to open — so the row has to say so
    // rather than pretend to be a button.
    if (kIsWeb) return false;
    try {
      final opened = await _appChannel.invokeMethod<bool>(
        'openNotificationSettings',
      );
      return opened ?? false;
    } catch (_) {
      // MissingPluginException on a platform with no handler for it.
      return false;
    }
  }

  @override
  Future<void> show(AppNotification notification, {bool sound = true}) async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.show(
        // Keyed on the ride so a second update replaces the first rather than
        // stacking. Trip progress should read as one running story, not as a
        // column of alerts about the same journey.
        id: notification.rideId?.hashCode ?? notification.id.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            // The Sounds setting. Still posted either way — it belongs in the
            // tray regardless — it just arrives without a noise.
            playSound: sound,
            // Safety is the one thing that should carry through Do Not
            // Disturb.
            category: notification.kind == NotificationKind.safety
                ? AndroidNotificationCategory.alarm
                : AndroidNotificationCategory.event,
          ),
          iOS: DarwinNotificationDetails(presentSound: sound),
        ),
        payload: notification.rideId,
      );
    } catch (_) {
      // Showing a notification is never worth an exception reaching a rider.
    }
  }
}
