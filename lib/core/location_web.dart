import 'dart:async';
import 'dart:js_interop';

import 'package:latlong2/latlong.dart';
import 'package:web/web.dart' as web;

/// The web side of [DeviceLocationService].
///
/// No method channel here — there is no native half to talk to. The browser
/// exposes geolocation directly, and it handles the permission prompt itself,
/// which is why this is shorter than either mobile implementation rather than
/// a port of one.
Future<LatLng?> readDeviceLocation() {
  final geolocation = web.window.navigator.geolocation;
  final done = Completer<LatLng?>();

  // getCurrentPosition calls back exactly once, but a Completer completed
  // twice throws, and a browser that misbehaves should not crash the app.
  void finish(LatLng? value) {
    if (!done.isCompleted) done.complete(value);
  }

  geolocation.getCurrentPosition(
    (web.GeolocationPosition position) {
      finish(LatLng(position.coords.latitude, position.coords.longitude));
    }.toJS,
    // Refused, unavailable, or timed out. All three mean the same thing to the
    // caller: carry on with the seeded location.
    (web.GeolocationPositionError _) {
      finish(null);
    }.toJS,
  );

  return done.future;
}
