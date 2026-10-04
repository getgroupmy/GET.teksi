import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// The Android and iOS side of [DeviceLocationService].
///
/// Both platforms answer on one channel with one method. The native code owns
/// the permission prompt, because that is where the prompt lives — a Dart
/// wrapper around it would only be a second place for the answer to go missing.
const _channel = MethodChannel('get.teksi/location');

/// A single fix, or null if there isn't one to be had.
///
/// Null is the honest answer to "permission refused", "location services off"
/// and "no fix yet" alike: the caller's behaviour is the same for all three,
/// and distinguishing them would mean showing the rider an error they cannot
/// act on from a screen that works fine without a fix.
Future<LatLng?> readDeviceLocation() async {
  final fix = await _channel.invokeMapMethod<String, double>('current');
  if (fix == null) return null;
  final lat = fix['lat'];
  final lng = fix['lng'];
  if (lat == null || lng == null) return null;
  return LatLng(lat, lng);
}
