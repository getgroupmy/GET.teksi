import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/geo.dart';
import 'package:latlong2/latlong.dart';

const _klcc = LatLng(3.1578, 101.7123);
const _midValley = LatLng(3.1177, 101.6771);
const _penang = LatLng(5.4141, 100.3288);

void main() {
  group('haversineKm', () {
    test('is zero for a point against itself', () {
      expect(haversineKm(_klcc, _klcc), closeTo(0, 0.0001));
    });

    test('matches a known city distance within a tolerance', () {
      // KLCC to Mid Valley is roughly 6 km as the crow flies.
      expect(haversineKm(_klcc, _midValley), closeTo(6.0, 1.0));
    });

    test('is symmetric', () {
      expect(
        haversineKm(_klcc, _penang),
        closeTo(haversineKm(_penang, _klcc), 0.0001),
      );
    });

    test('handles long distances', () {
      // Kuala Lumpur to Penang is roughly 300 km.
      expect(haversineKm(_klcc, _penang), closeTo(300, 40));
    });
  });

  group('bearingBetween', () {
    test('reads due north', () {
      expect(
        bearingBetween(const LatLng(0, 0), const LatLng(1, 0)),
        closeTo(0, 0.5),
      );
    });

    test('reads due east', () {
      expect(
        bearingBetween(const LatLng(0, 0), const LatLng(0, 1)),
        closeTo(90, 0.5),
      );
    });

    test('always returns a value inside 0..360', () {
      final rng = Random(7);
      for (var i = 0; i < 50; i++) {
        final a = LatLng(
          rng.nextDouble() * 160 - 80,
          rng.nextDouble() * 360 - 180,
        );
        final b = LatLng(
          rng.nextDouble() * 160 - 80,
          rng.nextDouble() * 360 - 180,
        );
        final result = bearingBetween(a, b);
        expect(result, inInclusiveRange(0, 360));
      }
    });
  });

  group('syntheticRoute', () {
    test('starts at the origin and ends at the destination', () {
      final path = syntheticRoute(_klcc, _midValley);
      expect(path.first.latitude, closeTo(_klcc.latitude, 0.0001));
      expect(path.last.latitude, closeTo(_midValley.latitude, 0.0001));
      expect(path.last.longitude, closeTo(_midValley.longitude, 0.0001));
    });

    test('is longer than the straight line but not a detour', () {
      final direct = haversineKm(_klcc, _midValley);
      final along = pathLengthKm(syntheticRoute(_klcc, _midValley));
      expect(along, greaterThanOrEqualTo(direct));
      expect(along, lessThan(direct * 1.6));
    });

    test('handles a zero-length route without dividing by zero', () {
      final path = syntheticRoute(_klcc, _klcc);
      expect(path, isNotEmpty);
      expect(
        path.every((p) => p.latitude.isFinite && p.longitude.isFinite),
        isTrue,
      );
    });
  });

  group('pointAlongPath', () {
    final path = syntheticRoute(_klcc, _midValley);

    test('fraction 0 is the start and 1 is the end', () {
      expect(
        pointAlongPath(path, 0).coord.latitude,
        closeTo(_klcc.latitude, 0.001),
      );
      expect(
        pointAlongPath(path, 1).coord.latitude,
        closeTo(_midValley.latitude, 0.001),
      );
    });

    test('clamps out-of-range fractions', () {
      expect(
        pointAlongPath(path, -5).coord.latitude,
        closeTo(_klcc.latitude, 0.001),
      );
      expect(
        pointAlongPath(path, 5).coord.latitude,
        closeTo(_midValley.latitude, 0.001),
      );
    });

    test('advances monotonically along the path', () {
      var previous = 0.0;
      for (var t = 0.0; t <= 1.0; t += 0.1) {
        final travelled = haversineKm(
          path.first,
          pointAlongPath(path, t).coord,
        );
        expect(travelled, greaterThanOrEqualTo(previous - 0.01));
        previous = travelled;
      }
    });

    test('copes with degenerate paths', () {
      expect(pointAlongPath(const [], 0.5).coord, const LatLng(0, 0));
      expect(pointAlongPath([_klcc], 0.5).coord, _klcc);
    });
  });

  group('roadDistanceKm', () {
    test('exceeds the straight line by the detour factor', () {
      expect(
        roadDistanceKm(_klcc, _midValley),
        closeTo(haversineKm(_klcc, _midValley) * 1.35, 0.001),
      );
    });
  });

  group('driveMinutes', () {
    test('never returns less than two minutes', () {
      expect(driveMinutes(0.05), greaterThanOrEqualTo(2));
    });

    test('grows with distance', () {
      expect(driveMinutes(20), greaterThan(driveMinutes(3)));
    });

    test('assumes highway speeds on long trips', () {
      // 100 km at highway speed should be well under two hours.
      expect(driveMinutes(100), lessThan(120));
    });
  });

  group('randomPointNear', () {
    test('stays inside the requested radius', () {
      final rng = Random(3);
      for (var i = 0; i < 100; i++) {
        final p = randomPointNear(_klcc, 3, rng);
        expect(haversineKm(_klcc, p), lessThanOrEqualTo(3.05));
      }
    });
  });
}
