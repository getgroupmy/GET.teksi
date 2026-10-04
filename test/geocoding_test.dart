import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/geocoding.dart';
import 'package:get_teksi/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

/// The offline index is a few hundred Malaysian places somebody typed out by
/// hand. It answers instantly and covers nowhere else, which for a ride-hailing
/// app means a passenger whose house is not on the list cannot be collected
/// from it. OpenStreetMap already draws the map and routes the car; this is the
/// third thing it knows.
///
/// What matters here is mostly what happens when the answer is bad — the shape
/// of this JSON is the part most likely to change under the app, and every
/// failure has to come back as "no results" rather than as an exception in a
/// search box.

const _kl = LatLng(3.1478, 101.6953);

/// One Nominatim hit, as the real service formats it: coordinates as strings,
/// a display_name that starts with the name and trails off into the country.
Map<String, dynamic> _hit({
  String name = 'KL Sentral',
  String lat = '3.1338',
  String lon = '101.6869',
  String category = 'railway',
  String type = 'station',
}) => {
  'place_id': 123,
  'osm_type': 'node',
  'osm_id': 456,
  'lat': lat,
  'lon': lon,
  'name': name,
  'display_name': '$name, Brickfields, Kuala Lumpur, 50470, Malaysia',
  'category': category,
  'type': type,
};

NominatimSearch _searchReturning(
  Object body, {
  int status = 200,
  void Function(http.Request)? onRequest,
}) => NominatimSearch(
  'https://nominatim.example/',
  client: MockClient((request) async {
    onRequest?.call(request);
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  }),
);

void main() {
  group('reading one result', () {
    test('a station becomes a place with its coordinates', () {
      final place = placeFromNominatim(_hit());

      expect(place, isNotNull);
      expect(place!.name, 'KL Sentral');
      expect(place.coord.latitude, closeTo(3.1338, 0.0001));
      expect(place.coord.longitude, closeTo(101.6869, 0.0001));
      expect(place.category, PlaceCategory.transit);
    });

    test('the address is the trail, without repeating the name', () {
      // display_name starts with the name, and showing it whole under a title
      // that already says it reads as a stutter.
      final place = placeFromNominatim(_hit())!;

      expect(place.address, 'Brickfields, Kuala Lumpur, 50470, Malaysia');
      expect(place.address, isNot(startsWith('KL Sentral')));
    });

    test('an address with no name of its own still gets a title', () {
      // Very common: a house number and street match has an empty name.
      final place = placeFromNominatim({
        ..._hit(),
        'name': '',
        'display_name': '12, Jalan Ampang, Kuala Lumpur, Malaysia',
      });

      expect(place, isNotNull);
      expect(place!.name, '12');
      expect(place.address, 'Jalan Ampang, Kuala Lumpur, Malaysia');
    });

    test('coordinates arrive as strings and are read as numbers', () {
      // The one that would be silently wrong rather than loudly broken: a hit
      // whose lat/lon never parsed would place a pin at the equator.
      final place = placeFromNominatim(_hit(lat: '5.4141', lon: '100.3288'))!;

      expect(place.coord.latitude, closeTo(5.4141, 0.0001));
    });

    test('a result with no usable position is dropped, not guessed', () {
      expect(placeFromNominatim({..._hit(), 'lat': 'north-ish'}), isNull);
      expect(placeFromNominatim({..._hit(), 'lon': null}), isNull);
      expect(placeFromNominatim('not a map'), isNull);
      expect(placeFromNominatim(null), isNull);
    });

    test('an unrecognised kind of place gets the neutral pin', () {
      // OpenStreetMap has thousands of tags and this app has five icons. A
      // wrong icon is worse than a plain one.
      final place = placeFromNominatim(
        _hit(category: 'amenity', type: 'veterinary'),
      )!;

      expect(place.category, PlaceCategory.area);
    });
  });

  group('asking the service', () {
    test('a search returns the places it found', () async {
      final search = _searchReturning([_hit(), _hit(name: 'KLCC')]);

      final results = await search.search('kl');
      expect(results, isEmpty, reason: 'two letters identify nowhere');

      final real = await search.search('kl sentral');
      expect(real.map((p) => p.name), ['KL Sentral', 'KLCC']);
    });

    test('a query too short to mean anything is not sent at all', () async {
      var calls = 0;
      final search = _searchReturning([_hit()], onRequest: (_) => calls++);

      await search.search('k');
      await search.search('kl');
      await search.search('  ');

      expect(calls, 0, reason: 'Nominatim asks for no unnecessary requests');
    });

    test('the position of the searcher biases without excluding', () async {
      // bounded=0: a viewbox that filtered would hide the airport someone in
      // town is trying to get to.
      Uri? asked;
      final search = _searchReturning([
        _hit(),
      ], onRequest: (r) => asked = r.url);

      await search.search('sentral', near: _kl);

      expect(asked!.queryParameters['viewbox'], isNotNull);
      expect(asked!.queryParameters['bounded'], '0');
      expect(asked!.queryParameters['countrycodes'], 'my');
      expect(asked!.queryParameters['format'], 'jsonv2');
    });

    test('searching everywhere is possible', () async {
      Uri? asked;
      final search = NominatimSearch(
        'https://nominatim.example',
        countryCodes: '',
        client: MockClient((r) async {
          asked = r.url;
          return http.Response('[]', 200);
        }),
      );

      await search.search('changi');

      expect(asked!.queryParameters.containsKey('countrycodes'), isFalse);
    });

    test('a server error is no results, not an exception', () async {
      final search = _searchReturning('nope', status: 503);

      expect(await search.search('kl sentral'), isEmpty);
    });

    test('nonsense on the wire is no results either', () async {
      expect(await _searchReturning('<html>').search('kl sentral'), isEmpty);
      expect(
        await _searchReturning({'error': 'rate limited'}).search('kl sentral'),
        isEmpty,
      );
    });

    test('an unreachable service is no results', () async {
      // The one a passenger will actually hit: a tunnel, a dead cell, a
      // rate limit. The offline index is still in front of this.
      final search = NominatimSearch(
        'https://nominatim.example',
        client: MockClient((_) async => throw const SocketExceptionLike()),
      );

      expect(await search.search('kl sentral'), isEmpty);
    });
  });

  group('choosing a search', () {
    tearDown(() => Geocoding.overrideWith(null));

    test('with nothing configured, nothing is asked of the network', () async {
      // The default, and what keeps the demo working with no provisioning at
      // all: the screen still has the offline index in front of this.
      expect(Geocoding.hasRemote, isFalse);
      expect(await Geocoding.remote.search('kl sentral'), isEmpty);
    });

    test('an override is used when one is set', () async {
      Geocoding.overrideWith(const _Fixed());

      expect(Geocoding.hasRemote, isTrue);
      expect((await Geocoding.remote.search('anything')).single.name, 'Fixed');
    });
  });

  group('the offline index', () {
    test('still answers, and without a network', () async {
      const offline = OfflinePlaceSearch();

      final results = await offline.search('klcc');

      expect(results, isNotEmpty);
      expect(results.first.name.toLowerCase(), contains('klcc'));
    });
  });
}

/// A throw that is not an http error, to prove the catch is not status-code
/// specific.
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}

class _Fixed implements PlaceSearch {
  const _Fixed();

  @override
  Future<List<Place>> search(String query, {LatLng? near}) async => const [
    Place(
      id: 'fixed',
      name: 'Fixed',
      address: 'Somewhere',
      coord: LatLng(3, 101),
    ),
  ];
}
