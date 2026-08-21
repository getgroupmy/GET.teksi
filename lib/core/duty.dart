import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the app running while a driver is on duty.
///
/// Stage 1 put ride events in front of someone who was not looking at the
/// screen, but only while the process happened to be alive. It usually is not:
/// a driver who switches to Waze or WhatsApp leaves this app in the
/// background, where Android is free to freeze it — and on the OEM builds this
/// app targets hardest, the ones with no Play Services, the aggressive
/// task-killers are the norm rather than the exception. A frozen process
/// reports no position, receives no realtime event, and rings no bell. The
/// driver looks online to the server and is unreachable in fact.
///
/// A foreground service is Android's answer to exactly that: an ongoing
/// notification in exchange for not being killed. It is also the honest trade
/// — the driver can see, at all times, that the app is still working, and the
/// notification is the affordance for stopping it.
///
/// **What this does not do.** The process survives being backgrounded; it does
/// not survive being swiped out of the recents list, which destroys the
/// Activity and with it the Flutter engine that runs all of this. Nor does it
/// help when the app was never started. Delivery to a closed app needs a push
/// transport — see docs/PLATFORMS.md.
abstract class DutyService {
  /// Returns whether the platform actually took it. False is a normal answer,
  /// not an error: the permission may be refused or the OS may decline the
  /// start, and the app then behaves exactly as it did before this existed.
  Future<bool> start({required String title, required String body});

  Future<void> stop();
}

/// Does nothing, everywhere that is not Android.
///
/// iOS has no equivalent that can be had for the asking: staying alive in the
/// background there means a background mode entitlement and an App Review
/// conversation about why a ride-hailing app needs one, which is a decision
/// for whoever owns the developer account rather than something to ship
/// switched on. Web has no concept of it at all.
class NoDutyService implements DutyService {
  const NoDutyService();

  @override
  Future<bool> start({required String title, required String body}) async =>
      false;

  @override
  Future<void> stop() async {}
}

/// Android's foreground service, over the channel `MainActivity` answers.
class AndroidDutyService implements DutyService {
  const AndroidDutyService();

  static const _channel = MethodChannel('get.teksi/duty');

  @override
  Future<bool> start({required String title, required String body}) async {
    try {
      final started = await _channel.invokeMethod<bool>('start', {
        'title': title,
        'body': body,
      });
      return started ?? false;
    } catch (_) {
      // MissingPluginException on a build without the native half, and
      // whatever the OS raises when it declines the start. Both mean the same
      // thing to the caller: no promise that the app stays awake.
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {
      // A service that will not stop on request still stops when the process
      // does, and there is nothing useful to tell the driver about it.
    }
  }
}

DutyService createDutyService() =>
    defaultTargetPlatform == TargetPlatform.android
    ? const AndroidDutyService()
    : const NoDutyService();
