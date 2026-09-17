import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'config.dart';
import 'geo.dart';

/// A route between waypoints: the line to draw, and the two numbers the fare
/// is computed from.
///
/// Distance is the part that matters beyond the drawing. The passenger names a
/// price anchored on it and the driver is paid that price, so a distance that
/// is off by the width of a river is a fare that is off by the same amount.
class RoadRoute {
  const RoadRoute({
    required this.geometry,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<LatLng> geometry;
  final double distanceKm;
  final int durationMinutes;
}

/// Where a route comes from.
///
/// Two implementations, chosen the same way the backend is: unconfigured, the
/// app synthesises geometry on-device and needs no network; configured with an
/// OSRM instance, the same build asks a real road network.
abstract class RouteService {
  /// Null means "no answer" — unreachable, timed out, or no route exists.
  /// Never throws: a passenger who cannot be routed is still a passenger who
  /// can be shown an estimate, so every caller falls back rather than failing.
  Future<RoadRoute?> route(List<LatLng> waypoints);
}

/// The on-device estimate. Straight-line distance with an urban detour factor,
/// and a plausible-looking line to draw.
///
/// It is an estimate and reads like one: 1.35 is right on average across a city
/// and wrong for any particular trip. It exists so the whole app works with
/// nothing provisioned, which is what makes the demo a demo.
class SyntheticRoutes implements RouteService {
  const SyntheticRoutes();

  @override
  Future<RoadRoute?> route(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    var km = 0.0;
    final geometry = <LatLng>[];
    for (var i = 0; i < waypoints.length - 1; i++) {
      km += roadDistanceKm(waypoints[i], waypoints[i + 1]);
      final leg = syntheticRoute(waypoints[i], waypoints[i + 1], 3);
      // Drop the duplicated joint so a multi-leg path is one continuous line.
      geometry.addAll(i == 0 ? leg : leg.skip(1));
    }
    return RoadRoute(
      geometry: geometry,
      distanceKm: double.parse(km.toStringAsFixed(2)),
      // A mid-route stop costs the driver a few minutes of waiting.
      durationMinutes: driveMinutes(km) + (waypoints.length - 2) * 4,
    );
  }
}

/// A real road network, via OSRM.
///
/// OSRM rather than a keyed provider because it is open source and
/// self-hostable, so this stays a URL in a config file rather than a vendor
/// account. The public demo server at router.project-osrm.org exists but is
/// explicitly not for production traffic; point this at your own.
class OsrmRoutes implements RouteService {
  OsrmRoutes(
    this.baseUrl, {
    http.Client? client,
    this.timeout = _defaultTimeout,
  }) : _client = client ?? http.Client();

  static const _defaultTimeout = Duration(seconds: 6);

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<RoadRoute?> route(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    // OSRM takes longitude first. Getting this backwards produces a route
    // through a plausible-looking part of the wrong hemisphere rather than an
    // error, which is why it is asserted in the tests rather than eyeballed.
    final coords = waypoints
        .map((w) => '${w.longitude},${w.latitude}')
        .join(';');
    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}'
      '/route/v1/driving/$coords'
      '?overview=full&geometries=polyline',
    );

    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map || body['code'] != 'Ok') return null;
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final first = routes.first;
      if (first is! Map) return null;

      final geometry = first['geometry'];
      final distance = first['distance'];
      final duration = first['duration'];
      if (geometry is! String || distance is! num || duration is! num) {
        return null;
      }

      final points = decodePolyline(geometry);
      if (points.length < 2) return null;

      return RoadRoute(
        geometry: points,
        // OSRM answers in metres and seconds.
        distanceKm: double.parse((distance / 1000).toStringAsFixed(2)),
        durationMinutes: math.max(1, (duration / 60).round()),
      );
    } catch (_) {
      // Unreachable, timed out, or nonsense on the wire. All the same to the
      // caller, which has an estimate to fall back on.
      return null;
    }
  }
}

/// Decodes an encoded polyline into coordinates.
///
/// This is Google's algorithm, which OSRM also speaks: each coordinate is a
/// delta from the last, zig-zag encoded so negatives stay small, then chunked
/// into five-bit groups with a continuation bit and shifted into printable
/// ASCII. Deltas are why a corrupted byte ruins the rest of the line rather
/// than one point of it.
///
/// [precision] is 5 for OSRM's `polyline` and 6 for `polyline6`.
List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
  final factor = math.pow(10, precision);
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  int nextDelta() {
    var shift = 0;
    var result = 0;
    int byte;
    do {
      if (index >= encoded.length) return 0;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    // Zig-zag: the low bit is the sign.
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += nextDelta();
    lng += nextDelta();
    points.add(LatLng(lat / factor, lng / factor));
  }
  return points;
}

/// The route service this build uses.
///
/// Resolved once, the same shape as [AppConfig.hasBackend]: a build with no
/// OSRM_URL keeps the on-device estimate and makes no network calls at all.
class Routing {
  const Routing._();

  static RouteService _service = AppConfig.hasRouting
      ? OsrmRoutes(AppConfig.osrmUrl)
      : const SyntheticRoutes();

  static RouteService get service => _service;

  /// True when routes come from a real road network rather than an estimate.
  static bool get isLive => _service is! SyntheticRoutes;

  /// For tests, and for anything that wants to force the on-device path.
  static void useService(RouteService service) => _service = service;
}
