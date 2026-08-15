import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// Default map centre — Kuala Lumpur city centre.
const cityCenter = LatLng(3.1478, 101.6953);
const cityName = 'Kuala Lumpur';

Place _p(String id, String name, String address, double lat, double lng, PlaceCategory c) =>
    Place(id: id, name: name, address: address, coord: LatLng(lat, lng), category: c);

/// Offline place index. Search works with no network at all.
final List<Place> places = [
  _p('p_klcc', 'Suria KLCC', 'Jalan Ampang, Kuala Lumpur City Centre', 3.1578, 101.7123, PlaceCategory.mall),
  _p('p_twin', 'Petronas Twin Towers', 'Kuala Lumpur City Centre', 3.1579, 101.7116, PlaceCategory.landmark),
  _p('p_klia', 'KLIA Terminal 1', 'Kuala Lumpur International Airport, Sepang', 2.7456, 101.7099, PlaceCategory.airport),
  _p('p_klia2', 'KLIA Terminal 2', 'KLIA2, Sepang', 2.7426, 101.6862, PlaceCategory.airport),
  _p('p_subang', 'Sultan Abdul Aziz Shah Airport', 'Subang, Selangor', 3.1304, 101.5493, PlaceCategory.airport),
  _p('p_sentral', 'KL Sentral', 'Jalan Stesen Sentral, Brickfields', 3.1338, 101.6869, PlaceCategory.transit),
  _p('p_pavilion', 'Pavilion Kuala Lumpur', 'Jalan Bukit Bintang, Bukit Bintang', 3.1490, 101.7132, PlaceCategory.mall),
  _p('p_bb', 'Bukit Bintang', 'Bukit Bintang, Kuala Lumpur', 3.1466, 101.7113, PlaceCategory.area),
  _p('p_midvalley', 'Mid Valley Megamall', 'Lingkaran Syed Putra, Mid Valley City', 3.1177, 101.6771, PlaceCategory.mall),
  _p('p_gardens', 'The Gardens Mall', 'Mid Valley City, Lingkaran Syed Putra', 3.1183, 101.6764, PlaceCategory.mall),
  _p('p_bangsar', 'Bangsar Village', 'Jalan Telawi 1, Bangsar', 3.1300, 101.6700, PlaceCategory.mall),
  _p('p_mont', 'Mont Kiara', 'Mont Kiara, Kuala Lumpur', 3.1710, 101.6500, PlaceCategory.area),
  _p('p_ttdi', 'Taman Tun Dr Ismail', 'TTDI, Kuala Lumpur', 3.1450, 101.6300, PlaceCategory.area),
  _p('p_damansara', 'The Curve, Mutiara Damansara', 'Jalan PJU 7/3, Petaling Jaya', 3.1580, 101.6110, PlaceCategory.mall),
  _p('p_1u', '1 Utama Shopping Centre', 'Bandar Utama, Petaling Jaya', 3.1502, 101.6155, PlaceCategory.mall),
  _p('p_sunway', 'Sunway Pyramid', 'Bandar Sunway, Subang Jaya', 3.0726, 101.6069, PlaceCategory.mall),
  _p('p_pj', 'Petaling Jaya SS2', 'SS2, Petaling Jaya, Selangor', 3.1180, 101.6230, PlaceCategory.area),
  _p('p_shah', 'Shah Alam i-City', 'Seksyen 7, Shah Alam', 3.0640, 101.4880, PlaceCategory.landmark),
  _p('p_puchong', 'IOI Mall Puchong', 'Bandar Puchong Jaya, Puchong', 3.0450, 101.6180, PlaceCategory.mall),
  _p('p_cheras', 'Cheras Leisure Mall', 'Taman Segar, Cheras', 3.0930, 101.7420, PlaceCategory.mall),
  _p('p_ampang', 'Ampang Park', 'Jalan Ampang, Kuala Lumpur', 3.1600, 101.7180, PlaceCategory.transit),
  _p('p_setapak', 'Wangsa Walk Mall', 'Wangsa Maju, Kuala Lumpur', 3.2020, 101.7350, PlaceCategory.mall),
  _p('p_putrajaya', 'Putrajaya Sentral', 'Presint 7, Putrajaya', 2.9310, 101.6710, PlaceCategory.transit),
  _p('p_cyber', 'Cyberjaya City Centre', 'Cyberjaya, Selangor', 2.9210, 101.6560, PlaceCategory.area),
  _p('p_batu', 'Batu Caves', 'Gombak, Selangor', 3.2379, 101.6840, PlaceCategory.landmark),
  _p('p_merdeka', 'Merdeka 118', 'Jalan Hang Jebat, Kuala Lumpur', 3.1416, 101.7009, PlaceCategory.landmark),
  _p('p_masjid', 'Masjid Jamek', 'Jalan Tun Perak, Kuala Lumpur', 3.1490, 101.6960, PlaceCategory.transit),
  _p('p_chinatown', 'Petaling Street', 'Chinatown, Kuala Lumpur', 3.1436, 101.6980, PlaceCategory.landmark),
  _p('p_titiwangsa', 'Titiwangsa Lake Gardens', 'Titiwangsa, Kuala Lumpur', 3.1780, 101.7020, PlaceCategory.landmark),
  _p('p_desapark', 'Desa ParkCity', 'Desa ParkCity, Kuala Lumpur', 3.1870, 101.6300, PlaceCategory.area),
  _p('p_hospital', 'Hospital Kuala Lumpur', 'Jalan Pahang, Kuala Lumpur', 3.1730, 101.6990, PlaceCategory.landmark),
  _p('p_um', 'Universiti Malaya', 'Jalan Universiti, Kuala Lumpur', 3.1209, 101.6538, PlaceCategory.landmark),
  _p('p_ioicity', 'IOI City Mall', 'Putrajaya, Selangor', 2.9690, 101.7130, PlaceCategory.mall),
  _p('p_klgateway', 'KL Gateway Mall', 'Kerinchi, Kuala Lumpur', 3.1140, 101.6640, PlaceCategory.mall),
  _p('p_tbs', 'Terminal Bersepadu Selatan', 'Bandar Tasik Selatan, Kuala Lumpur', 3.0760, 101.7110, PlaceCategory.transit),
  _p('p_bukitjalil', 'Bukit Jalil National Stadium', 'Bukit Jalil, Kuala Lumpur', 3.0545, 101.6913, PlaceCategory.landmark),
  _p('p_pavilion2', 'Pavilion Bukit Jalil', 'Bukit Jalil, Kuala Lumpur', 3.0590, 101.6870, PlaceCategory.mall),
  _p('p_setiawalk', 'SetiaWalk Puchong', 'Pusat Bandar Puchong', 3.0230, 101.6180, PlaceCategory.mall),
  _p('p_klang', 'Klang Town Centre', 'Klang, Selangor', 3.0450, 101.4450, PlaceCategory.area),
  _p('p_genting', 'Genting Highlands', 'Bentong, Pahang', 3.4230, 101.7930, PlaceCategory.landmark),
];

/// Destinations offered in the Intercity vertical.
final List<Place> intercityPlaces = [
  _p('ic_ipoh', 'Ipoh', 'Perak', 4.5975, 101.0901, PlaceCategory.area),
  _p('ic_penang', 'George Town, Penang', 'Pulau Pinang', 5.4141, 100.3288, PlaceCategory.area),
  _p('ic_melaka', 'Melaka', 'Melaka', 2.1896, 102.2501, PlaceCategory.area),
  _p('ic_jb', 'Johor Bahru', 'Johor', 1.4927, 103.7414, PlaceCategory.area),
  _p('ic_seremban', 'Seremban', 'Negeri Sembilan', 2.7297, 101.9381, PlaceCategory.area),
  _p('ic_kuantan', 'Kuantan', 'Pahang', 3.8077, 103.3260, PlaceCategory.area),
  _p('ic_cameron', 'Cameron Highlands', 'Pahang', 4.4711, 101.3776, PlaceCategory.area),
];

final List<Place> allPlaces = [...places, ...intercityPlaces];

/// Street names used to synthesise "dropped pin" addresses.
const streets = [
  'Jalan Ampang', 'Jalan Sultan Ismail', 'Jalan Raja Chulan', 'Jalan Tun Razak',
  'Jalan Bukit Bintang', 'Jalan Imbi', 'Jalan Pudu', 'Jalan Kuching',
  'Jalan Ipoh', 'Jalan Cheras', 'Jalan Klang Lama', 'Jalan Duta',
  'Persiaran KLCC', 'Lebuh Ampang', 'Jalan Sultan Hishamuddin', 'Jalan Damansara',
];

List<Place> fuzzySearch(String query, {List<Place>? pool, int limit = 8}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final source = pool ?? allPlaces;
  final words = q.split(RegExp(r'\s+'));

  final scored = <({Place place, int score})>[];
  for (final place in source) {
    final name = place.name.toLowerCase();
    final address = place.address.toLowerCase();
    var score = 0;
    if (name.startsWith(q)) {
      score += 100;
    } else if (name.contains(q)) {
      score += 60;
    }
    if (address.contains(q)) score += 25;
    // Match on individual words so "mid valley" finds "Mid Valley Megamall".
    if (words.length > 1 &&
        words.every((w) => name.contains(w) || address.contains(w))) {
      score += 40;
    }
    if (score > 0) scored.add((place: place, score: score));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).map((s) => s.place).toList();
}
