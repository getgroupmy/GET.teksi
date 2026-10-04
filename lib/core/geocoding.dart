import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../data/places.dart';
import '../models/models.dart';
import 'config.dart';

/// Where a place comes from when someone types a destination.
///
/// The app shipped with an offline index: a few hundred Malaysian places
/// written into lib/data/places.dart by hand. That is what makes search work
/// with no network at all, and it is also the ceiling on where anyone can go —
/// a passenger whose house is not on the list cannot be collected from it,
/// which for a ride-hailing app is not a rough edge but the whole product.
///
/// OpenStreetMap already draws the map and already routes the car. This is the
/// third thing it knows: what places are called and where they are. Same data,
/// same licence, one more seam.
abstract class PlaceSearch {
  /// Never throws, and an empty list is a normal answer. A passenger typing
  /// into a search box while a request times out should see the offline
  /// matches, not an error.
  Future<List<Place>> search(String query, {LatLng? near});
}

/// The hand-listed index, matched with the same fuzzy search the app has
/// always used. No network, and no places nobody thought of.
class OfflinePlaceSearch implements PlaceSearch {
  const OfflinePlaceSearch({this.pool, this.limit = 8});

  /// Null means the default index. The intercity screen passes its own.
  final List<Place>? pool;
  final int limit;

  @override
  Future<List<Place>> search(String query, {LatLng? near}) async =>
      fuzzySearch(query, pool: pool, limit: limit);
}

/// OpenStreetMap's own geocoder.
///
/// Nominatim rather than a keyed provider, for the same reason the router is
/// OSRM: it is open source and self-hostable, so this stays a URL rather than
/// a vendor account, and the answers come from the same database that drew the
/// tiles underneath them.
class NominatimSearch implements PlaceSearch {
  NominatimSearch(
    this.baseUrl, {
    http.Client? client,
    this.timeout = _defaultTimeout,
    this.limit = 8,
    this.countryCodes = 'my',
  }) : _client = client ?? http.Client();

  /// Shorter than the router's. This runs while someone is typing, and a
  /// search box that pauses for six seconds reads as broken.
  static const _defaultTimeout = Duration(seconds: 4);

  final String baseUrl;
  final Duration timeout;
  final int limit;

  /// Restricts results to a country. Malaysia by default, because a passenger
  /// in Kuala Lumpur searching "Sentral" wants KL Sentral rather than a street
  /// in Portugal. Pass an empty string to search everywhere.
  final String countryCodes;

  final http.Client _client;

  @override
  Future<List<Place>> search(String query, {LatLng? near}) async {
    final q = query.trim();
    // Nominatim's policy asks for no unnecessary requests, and one or two
    // letters cannot identify anywhere anyway.
    if (q.length < 3) return const [];

    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/search')
        .replace(
          queryParameters: {
            'q': q,
            'format': 'jsonv2',
            'limit': '$limit',
            'addressdetails': '1',
            if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
            // Prefer results near the searcher without excluding everywhere else:
            // bounded=0 means this ranks rather than filters.
            if (near != null) ...{
              'viewbox': _viewboxAround(near),
              'bounded': '0',
            },
          },
        );

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body);
      if (body is! List) return const [];
      return body.map(placeFromNominatim).nonNulls.toList();
    } catch (_) {
      // Unreachable, timed out, rate-limited, or nonsense on the wire. All the
      // same to the caller, which still has the offline index.
      return const [];
    }
  }

  /// Roughly 50 km around a point, as Nominatim wants it: left, top, right,
  /// bottom. Longitude degrees shrink towards the poles; at Malaysian
  /// latitudes the difference is under two percent, so this does not bother.
  static String _viewboxAround(LatLng at) {
    const halfDegree = 0.45;
    final left = at.longitude - halfDegree;
    final right = at.longitude + halfDegree;
    final top = at.latitude + halfDegree;
    final bottom = at.latitude - halfDegree;
    return '$left,$top,$right,$bottom';
  }
}

/// One Nominatim result as a [Place], or null if it is not usable.
///
/// Split out and given a name because the shape of this JSON is the part most
/// likely to be wrong: `lat` and `lon` arrive as strings, `name` is often empty
/// for an address-only match, and `display_name` is a long comma-separated
/// trail that reads badly as a title and well as a subtitle.
Place? placeFromNominatim(Object? json) {
  if (json is! Map) return null;

  final lat = double.tryParse('${json['lat']}');
  final lon = double.tryParse('${json['lon']}');
  if (lat == null || lon == null) return null;

  final display = '${json['display_name'] ?? ''}'.trim();
  var name = '${json['name'] ?? ''}'.trim();
  if (name.isEmpty) {
    // An address with no name of its own: take the first segment of the
    // display name, which is the house number and street.
    name = display.split(',').first.trim();
  }
  if (name.isEmpty) return null;

  // The rest of the trail, minus the bit already used as the title.
  final rest = display.startsWith(name)
      ? display.substring(name.length).replaceFirst(RegExp(r'^,\s*'), '')
      : display;

  final id =
      '${json['osm_type'] ?? 'osm'}_${json['osm_id'] ?? json['place_id']}';
  return Place(
    id: id,
    name: name,
    address: rest.isEmpty ? display : rest,
    coord: LatLng(lat, lon),
    category: _categoryFor(
      '${json['category'] ?? ''}',
      '${json['type'] ?? ''}',
    ),
  );
}

/// Nominatim's OSM tags, mapped onto the handful of icons this app draws.
///
/// OpenStreetMap has thousands of tags and this app has five pins, so most of
/// the mapping is deliberate loss. Anything unrecognised is an area, which is
/// the neutral one — a wrong icon is worse than a plain one.
PlaceCategory _categoryFor(String category, String type) => switch ((
  category,
  type,
)) {
  ('aeroway', _) || (_, 'airport') || (_, 'aerodrome') => PlaceCategory.airport,
  ('railway', _) ||
  (_, 'station') ||
  (_, 'bus_station') ||
  (_, 'halt') => PlaceCategory.transit,
  ('shop', _) || (_, 'mall') || (_, 'supermarket') => PlaceCategory.mall,
  ('tourism', _) ||
  ('historic', _) ||
  (_, 'attraction') ||
  (_, 'university') ||
  (_, 'hospital') => PlaceCategory.landmark,
  _ => PlaceCategory.area,
};

/// The search the app uses, chosen the way the backend and the router are.
///
/// Unconfigured it is the offline index, which is what keeps the demo working
/// with nothing provisioned. Configured, it is OpenStreetMap — and the offline
/// index stays in front of it, because a place someone has already been to
/// should appear the instant they type rather than after a round trip.
class Geocoding {
  const Geocoding._();

  static PlaceSearch? _override;

  /// For tests, which have no business making a network call.
  static void overrideWith(PlaceSearch? search) => _override = search;

  static PlaceSearch get remote =>
      _override ??
      (AppConfig.hasGeocoding
          ? NominatimSearch(AppConfig.nominatimUrl)
          : const _NoRemote());

  static bool get hasRemote => _override != null || AppConfig.hasGeocoding;
}

/// Answers nothing, so a caller that always asks costs nothing when there is
/// no geocoder configured.
class _NoRemote implements PlaceSearch {
  const _NoRemote();

  @override
  Future<List<Place>> search(String query, {LatLng? near}) async => const [];
}
