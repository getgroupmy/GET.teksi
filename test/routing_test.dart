import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/routing.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/state/draft.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Routing decides the distance, the distance decides the recommended fare, and
/// the fare is what the driver is paid. A route through the wrong hemisphere
/// does not throw — it returns a confident number that is wrong, which is the
/// failure mode these are shaped around.

const _pickup = Place(
  id: 'p1',
  name: 'KL Sentral',
  address: 'Brickfields',
  coord: LatLng(3.1338, 101.6869),
);
const _dropoff = Place(
  id: 'p2',
  name: 'Suria KLCC',
  address: 'KLCC',
  coord: LatLng(3.1578, 101.7123),
);

/// An OSRM that answers from a script and records what it was asked.
http.Client _osrm({required String body, int status = 200, List<Uri>? seen}) {
  return MockClient((request) async {
    seen?.add(request.url);
    return http.Response(body, status);
  });
}

String _okResponse({
  required String geometry,
  required double metres,
  required double seconds,
}) => jsonEncode({
  'code': 'Ok',
  'routes': [
    {'geometry': geometry, 'distance': metres, 'duration': seconds},
  ],
});

/// KL Sentral → KLCC, encoded at precision 5.
const _geometry = '_dl@_ashS_pR_pR';

void main() {
  group('polyline', () {
    test('decodes to the coordinates it was built from', () {
      // The canonical example from Google's own specification, which is the
      // only way to check a decoder without reimplementing the encoder.
      final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 0.00001));
      expect(points[0].longitude, closeTo(-120.2, 0.00001));
      expect(points[1].latitude, closeTo(40.7, 0.00001));
      expect(points[1].longitude, closeTo(-120.95, 0.00001));
      expect(points[2].latitude, closeTo(43.252, 0.00001));
      expect(points[2].longitude, closeTo(-126.453, 0.00001));
    });

    test('a truncated line stops rather than running off the end', () {
      // Deltas mean a cut-short string is a shorter route, not a crash.
      expect(() => decodePolyline('_p~iF~ps|U_ulLnnq'), returnsNormally);
    });
  });

  group('OsrmRoutes', () {
    test('asks for longitude first, which OSRM requires', () async {
      // Swapping these produces a plausible route through the wrong part of the
      // world rather than an error, so the request itself is the assertion.
      final seen = <Uri>[];
      final service = OsrmRoutes(
        'https://routing.example',
        client: _osrm(
          body: _okResponse(geometry: _geometry, metres: 5000, seconds: 900),
          seen: seen,
        ),
      );
      await service.route([_pickup.coord, _dropoff.coord]);

      expect(seen, hasLength(1));
      expect(seen.single.path, contains('101.6869,3.1338;101.7123,3.1578'));
    });

    test('converts metres and seconds into the app units', () async {
      final service = OsrmRoutes(
        'https://routing.example',
        client: _osrm(
          body: _okResponse(geometry: _geometry, metres: 5480, seconds: 933),
        ),
      );
      final route = await service.route([_pickup.coord, _dropoff.coord]);

      expect(route, isNotNull);
      expect(route!.distanceKm, 5.48);
      expect(route.durationMinutes, 16);
    });

    test('a trailing slash on the base URL does not double up', () async {
      final seen = <Uri>[];
      final service = OsrmRoutes(
        'https://routing.example/',
        client: _osrm(
          body: _okResponse(geometry: _geometry, metres: 100, seconds: 60),
          seen: seen,
        ),
      );
      await service.route([_pickup.coord, _dropoff.coord]);

      expect(seen.single.path, startsWith('/route/v1/driving/'));
    });

    test('a sub-minute trip still reads as a minute', () async {
      // Rounding 20 seconds to zero would show "0 min" on the order card.
      final service = OsrmRoutes(
        'https://routing.example',
        client: _osrm(
          body: _okResponse(geometry: _geometry, metres: 200, seconds: 20),
        ),
      );
      final route = await service.route([_pickup.coord, _dropoff.coord]);
      expect(route!.durationMinutes, 1);
    });

    test('every way of failing comes back as null', () async {
      Future<RoadRoute?> ask(String body, {int status = 200}) => OsrmRoutes(
        'https://routing.example',
        client: _osrm(body: body, status: status),
      ).route([_pickup.coord, _dropoff.coord]);

      expect(await ask('', status: 500), isNull, reason: 'server error');
      expect(await ask('not json'), isNull, reason: 'garbage on the wire');
      expect(
        await ask(jsonEncode({'code': 'NoRoute', 'routes': <void>[]})),
        isNull,
        reason: 'no route exists',
      );
      expect(
        await ask(jsonEncode({'code': 'Ok', 'routes': <void>[]})),
        isNull,
        reason: 'empty route list',
      );
      expect(
        await ask(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {'geometry': _geometry, 'distance': 'far', 'duration': 900},
            ],
          }),
        ),
        isNull,
        reason: 'distance is not a number',
      );
    });

    test('one waypoint is not a route', () async {
      final service = OsrmRoutes(
        'https://routing.example',
        client: _osrm(
          body: _okResponse(geometry: _geometry, metres: 1, seconds: 1),
        ),
      );
      expect(await service.route([_pickup.coord]), isNull);
    });
  });

  group('SyntheticRoutes', () {
    test('answers without a network and keeps the detour factor', () async {
      const service = SyntheticRoutes();
      final route = await service.route([_pickup.coord, _dropoff.coord]);

      expect(route, isNotNull);
      // Straight line is ~3.9 km here; the estimate applies 1.35×.
      expect(route!.distanceKm, greaterThan(4.5));
      expect(route.distanceKm, lessThan(6.0));
      expect(route.geometry.length, greaterThan(2));
    });

    test('a stop makes the trip longer, not shorter', () async {
      const service = SyntheticRoutes();
      const via = LatLng(3.1200, 101.7500);
      final direct = await service.route([_pickup.coord, _dropoff.coord]);
      final viaStop = await service.route([_pickup.coord, via, _dropoff.coord]);

      expect(viaStop!.distanceKm, greaterThan(direct!.distanceKm));
      expect(viaStop.durationMinutes, greaterThan(direct.durationMinutes));
    });
  });

  group('the fare anchor', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.init();
    });

    tearDown(() => Routing.useService(const SyntheticRoutes()));

    test('shows an estimate immediately, then refines it', () async {
      // The screen must never wait on a network call to show a price. The
      // estimate is there on the same turn; the routed number replaces it when
      // it lands.
      Routing.useService(
        OsrmRoutes(
          'https://routing.example',
          client: _osrm(
            body: _okResponse(geometry: _geometry, metres: 9000, seconds: 1200),
          ),
        ),
      );
      final draft = DraftStore()..setPickup(_pickup);
      draft.setDropoff(_dropoff);

      final estimated = draft.trip!;
      expect(estimated.routed, isFalse);
      expect(estimated.distanceKm, lessThan(6));

      await Future<void>.delayed(Duration.zero);

      final routed = draft.trip!;
      expect(routed.routed, isTrue);
      expect(routed.distanceKm, 9.0);
      // The fare followed the distance rather than staying on the estimate.
      expect(routed.recommended, greaterThan(estimated.recommended));
      expect(draft.price, routed.recommended);
    });

    test('a price the passenger set is not overwritten by a late route', () {
      // Naming the fare is the product. A route arriving afterwards may move
      // the recommendation but must not move their number.
      Routing.useService(
        OsrmRoutes(
          'https://routing.example',
          client: _osrm(
            body: _okResponse(geometry: _geometry, metres: 9000, seconds: 1200),
          ),
        ),
      );
      final draft = DraftStore()..setPickup(_pickup);
      draft.setDropoff(_dropoff);
      draft.setPrice(4200);

      return Future<void>.delayed(Duration.zero).then((_) {
        expect(draft.trip!.routed, isTrue);
        expect(draft.price, 4200);
      });
    });

    test('a route for a trip the passenger abandoned is dropped', () async {
      // The reply outlives the question. Applying it would price the trip they
      // are looking at using the distance of one they are not.
      Routing.useService(
        OsrmRoutes(
          'https://routing.example',
          client: _osrm(
            body: _okResponse(
              geometry: _geometry,
              metres: 40000,
              seconds: 3600,
            ),
          ),
        ),
      );
      final draft = DraftStore()..setPickup(_pickup);
      draft.setDropoff(_dropoff);
      draft.setDropoff(null);
      await Future<void>.delayed(Duration.zero);

      expect(draft.trip, isNull);
      expect(draft.routeGeometry, isNull);
    });

    test('an unreachable router leaves the estimate standing', () async {
      Routing.useService(
        OsrmRoutes(
          'https://routing.example',
          client: _osrm(body: '', status: 503),
        ),
      );
      final draft = DraftStore()..setPickup(_pickup);
      draft.setDropoff(_dropoff);
      await Future<void>.delayed(Duration.zero);

      final trip = draft.trip!;
      expect(trip.routed, isFalse);
      expect(trip.distanceKm, greaterThan(0));
      expect(draft.price, trip.recommended);
    });
  });
}
