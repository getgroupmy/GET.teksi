import 'package:latlong2/latlong.dart';

import '../data/places.dart';
import 'location_channel.dart' if (dart.library.js_interop) 'location_web.dart';

/// Where the device is.
///
/// One method, deliberately. Nothing above this reads the platform, which is
/// what let the whole app be built and tested before any of it existed.
abstract class LocationService {
  Future<LatLng?> current();
}

/// The city centre, always. Used by the test suite and as the fallback for a
/// platform that has no answer.
class SeededLocationService implements LocationService {
  const SeededLocationService();

  @override
  Future<LatLng?> current() async => cityCenter;
}

/// The real thing: GPS on Android and iOS, the browser's geolocation on web.
///
/// Notably *not* `geolocator`, which is the obvious choice and the wrong one
/// here — its Android implementation depends on
/// `com.google.android.gms:play-services-location`, which would put Play
/// Services back into the dependency graph and make the APK refuse to locate
/// anyone on a Huawei device. The platform's own LocationManager has been in
/// Android since API 1 and needs nothing from Google.
///
/// Returns null rather than throwing on every failure — permission refused,
/// location switched off, no fix before the timeout, running somewhere with no
/// implementation at all. A rider who declines the permission gets an app that
/// opens on the city centre and lets them drag the pin, which is how pickup
/// adjustment works anyway.
class DeviceLocationService implements LocationService {
  const DeviceLocationService({this.timeout = const Duration(seconds: 10)});

  /// A first fix outdoors is usually seconds; indoors it can be never. The app
  /// is usable without one, so waiting forever buys nothing.
  final Duration timeout;

  @override
  Future<LatLng?> current() async {
    try {
      return await readDeviceLocation().timeout(timeout, onTimeout: () => null);
    } catch (_) {
      // Includes MissingPluginException, which is what a platform with no
      // implementation raises. Not an error — just no answer.
      return null;
    }
  }
}
