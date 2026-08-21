import 'package:flutter/foundation.dart';
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
          // Web included, deliberately. Browsers only honour a permission
          // request made during a user gesture, and this is called a frame
          // after sign-in — by then the gesture has expired and the request
          // is refused outright, which is worse than not asking: the browser
          // remembers the refusal. Web needs a button, which is a screen, not
          // a platform seam.
          return;
      }
    } catch (_) {
      // A refused or unavailable permission means a quieter app, not a broken
      // one. The in-app centre still has everything.
    }
  }

  @override
  Future<void> show(AppNotification notification) async {
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
            // Safety is the one thing that should carry through Do Not
            // Disturb.
            category: notification.kind == NotificationKind.safety
                ? AndroidNotificationCategory.alarm
                : AndroidNotificationCategory.event,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: notification.rideId,
      );
    } catch (_) {
      // Showing a notification is never worth an exception reaching a rider.
    }
  }
}
