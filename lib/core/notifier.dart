import '../models/models.dart';
import 'notifier_device.dart';

/// Whether this device will actually show what the app raises.
enum NotificationPermission {
  /// Notifications reach the tray.
  granted,

  /// Refused, or switched off later. The in-app centre still has everything;
  /// nothing else does.
  denied,

  /// No notification manager here at all — the test suite, and any platform
  /// with no implementation.
  unavailable,
}

/// Puts a notification in front of someone who is not looking at the app.
///
/// The in-app centre is a screen you have to visit. A driver waiting for orders
/// is looking at the road, and a passenger who has put their phone in a pocket
/// finds out their driver arrived when they take it out again. The bell only
/// works if it makes a sound.
///
/// Deliberately *not* Firebase Cloud Messaging, which is the obvious answer and
/// the wrong one here for the same reason `geolocator` was: it drags Play
/// Services into the dependency graph and the APK stops working on a Huawei
/// device. What this uses is the platform's own notification manager, which
/// owes Google nothing — the trade is that it can only fire while the process
/// is alive. Real delivery to a closed app needs a push transport, and the
/// GMS-free routes to that are in docs/PLATFORMS.md.
abstract class Notifier {
  /// Asks, if the platform still has a prompt to show. Never throws: a refused
  /// permission is a quieter app, not a broken one.
  ///
  /// Worth calling from a button rather than on a timer. Browsers only honour
  /// the request during a user gesture, and on Android and iOS a prompt
  /// nobody asked for is the one people dismiss on reflex.
  Future<void> requestPermission();

  /// What the platform says right now, rather than what the app last asked
  /// for. Permission is revocable from outside the app, so the only honest
  /// answer comes from asking again.
  Future<NotificationPermission> status();

  /// Opens the place where this permission is actually changed.
  ///
  /// Returns false when there is nowhere to go — a browser, most of all, where
  /// the notification permission lives in a UI no page is allowed to open. The
  /// caller then has to say so rather than leaving a row that does nothing.
  Future<bool> openSettings();

  /// [sound] carries the Sounds setting. False still posts the notification —
  /// it belongs in the tray either way — it just arrives silently.
  Future<void> show(AppNotification notification, {bool sound = true});
}

/// Does nothing, and says so.
///
/// The default everywhere the platform has no answer — the test suite, and any
/// build where notifications are switched off. Every caller treats a silent
/// notifier as normal rather than as a failure, which is what keeps the app
/// running with no bindings at all.
class SilentNotifier implements Notifier {
  const SilentNotifier();

  @override
  Future<void> requestPermission() async {}

  @override
  Future<NotificationPermission> status() async =>
      NotificationPermission.unavailable;

  @override
  Future<bool> openSettings() async => false;

  @override
  Future<void> show(AppNotification notification, {bool sound = true}) async {}
}

/// The platform's notification manager, or a silent one where there is none.
Notifier createNotifier() => buildNotifier();
