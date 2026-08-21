import '../models/models.dart';
import 'notifier_device.dart';

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
  /// Asks once, if the platform requires asking. Never throws: a refused
  /// permission is a quieter app, not a broken one.
  Future<void> requestPermission();

  Future<void> show(AppNotification notification);
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
  Future<void> show(AppNotification notification) async {}
}

/// The platform's notification manager, or a silent one where there is none.
Notifier createNotifier() => buildNotifier();
