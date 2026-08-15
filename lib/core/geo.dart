import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

const _earthRadiusKm = 6371.0;

double _toRad(double deg) => deg * math.pi / 180;
double _toDeg(double rad) => rad * 180 / math.pi;

/// Great-circle distance in kilometres.
double haversineKm(LatLng a, LatLng b) {
  final dLat = _toRad(b.latitude - a.latitude);
  final dLng = _toRad(b.longitude - a.longitude);
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat + sinLng * sinLng * math.cos(lat1) * math.cos(lat2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(h));
}

/// Compass bearing from [a] to [b], in degrees clockwise from north.
double bearingBetween(LatLng a, LatLng b) {
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final dLng = _toRad(b.longitude - a.longitude);
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (_toDeg(math.atan2(y, x)) + 360) % 360;
}

/// Linear interpolation between two coordinates — fine at city scale.
LatLng lerpCoord(LatLng a, LatLng b, double t) => LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );

/// Random point within [radiusKm] of [center], uniform by area.
LatLng randomPointNear(LatLng center, double radiusKm, math.Random rng) {
  final r = radiusKm * math.sqrt(rng.nextDouble());
  final theta = rng.nextDouble() * 2 * math.pi;
  final dLat = (r / _earthRadiusKm) * (180 / math.pi);
  final dLng = dLat / math.cos(_toRad(center.latitude));
  return LatLng(
    center.latitude + dLat * math.sin(theta),
    center.longitude + dLng * math.cos(theta),
  );
}

/// Total length of a polyline in kilometres.
double pathLengthKm(List<LatLng> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += haversineKm(path[i - 1], path[i]);
  }
  return total;
}

class PathPoint {
  const PathPoint(this.coord, this.bearing);
  final LatLng coord;
  final double bearing;
}

/// Position at [fraction] (0..1) along a polyline, plus the heading there.
/// Used to animate a car along its route.
PathPoint pointAlongPath(List<LatLng> path, double fraction) {
  if (path.isEmpty) return PathPoint(const LatLng(0, 0), 0);
  if (path.length == 1) return PathPoint(path.first, 0);
  final clamped = fraction.clamp(0.0, 1.0);
  final target = pathLengthKm(path) * clamped;
  var travelled = 0.0;
  for (var i = 1; i < path.length; i++) {
    final segment = haversineKm(path[i - 1], path[i]);
    if (travelled + segment >= target || i == path.length - 1) {
      final t = segment == 0 ? 0.0 : (target - travelled) / segment;
      return PathPoint(
        lerpCoord(path[i - 1], path[i], t.clamp(0.0, 1.0)),
        bearingBetween(path[i - 1], path[i]),
      );
    }
    travelled += segment;
  }
  return PathPoint(path.last, 0);
}

/// Builds a plausible road-like path between two points without a routing
/// server: bend the straight line with a perpendicular offset and add small
/// jitter so it reads as streets rather than a ruler line.
List<LatLng> syntheticRoute(LatLng from, LatLng to, [int seed = 1]) {
  const steps = 24;
  final dist = haversineKm(from, to);
  // Bend more on long trips, but never so much that it looks like a detour.
  final amplitude = math.min(0.12, dist * 0.02);
  final dLat = to.latitude - from.latitude;
  final dLng = to.longitude - from.longitude;
  final len = math.sqrt(dLat * dLat + dLng * dLng);
  final safeLen = len == 0 ? 1.0 : len;
  // Unit perpendicular to the direct line.
  final pLat = -dLng / safeLen;
  final pLng = dLat / safeLen;
  final dir = seed.isEven ? 1 : -1;

  final path = <LatLng>[from];
  // Interior points only: the endpoints stay exactly on the pickup and
  // dropoff pins, so the drawn line never floats away from its markers.
  for (var i = 1; i < steps; i++) {
    final t = i / steps;
    final base = lerpCoord(from, to, t);
    final wobble = math.sin(t * math.pi) * amplitude;
    final off = wobble * dir * 0.01;
    // A little stair-stepping to suggest a grid of streets.
    final jitter = math.sin(t * math.pi * 6 + seed) * amplitude * 0.0015;
    path.add(LatLng(base.latitude + pLat * off + jitter, base.longitude + pLng * off));
  }
  path.add(to);
  return path;
}

/// Road distance estimate. Real road networks are longer than the crow flies;
/// 1.35 is a reasonable urban detour factor.
double roadDistanceKm(LatLng from, LatLng to) => haversineKm(from, to) * 1.35;

/// Rough driving time for a distance, assuming mixed urban traffic.
int driveMinutes(double km) {
  final avgSpeedKmh = km > 25
      ? 65.0
      : km > 8
          ? 38.0
          : 24.0;
  return math.max(2, ((km / avgSpeedKmh) * 60).round());
}
