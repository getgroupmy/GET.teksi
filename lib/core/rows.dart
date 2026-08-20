import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// Translation between the domain models and Postgres rows.
///
/// The models already serialise themselves to JSON for local storage, but that
/// shape is deliberately not the database shape: local JSON is camelCase with
/// millisecond integers for time, while the tables are snake_case with real
/// `timestamptz`, real enums and coordinates lifted into their own columns so
/// the server can index and filter on them. Keeping the two conversions
/// separate means the on-device format can stay frozen for backwards
/// compatibility while the schema evolves, and vice versa.
///
/// Everything here is pure, so it is tested without a database or a network.

String? _iso(DateTime? t) => t?.toUtc().toIso8601String();

DateTime? _time(Object? raw) {
  if (raw == null) return null;
  return DateTime.parse(raw as String).toLocal();
}

double _double(Object? raw) => (raw as num).toDouble();

/// PostgREST returns `numeric` columns as JSON numbers, but a driver that
/// widens one to text should degrade rather than crash a live ride.
double? _maybeDouble(Object? raw) => switch (raw) {
  null => null,
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

LatLng? _coord(Object? lat, Object? lng) {
  if (lat == null || lng == null) return null;
  return LatLng(_double(lat), _double(lng));
}

Map<String, dynamic> _place(Place p) => p.toJson();

Place _placeFrom(Object? raw) =>
    Place.fromJson((raw as Map).cast<String, dynamic>());

// ---------------------------------------------------------------------------
// Rides
// ---------------------------------------------------------------------------

/// The columns a client is allowed to write when publishing a ride.
///
/// Driver fields, `final_price` and the trip timestamps are absent by design —
/// the database rejects a passenger writing them, so sending them would be a
/// wasted round trip and a misleading read of the code.
Map<String, dynamic> rideToInsert(Ride r) => {
  'id': r.id,
  'passenger_id': r.passengerId,
  'passenger_name': r.passengerName,
  'passenger_avatar_color': r.passengerAvatarColor,
  'passenger_rating': r.passengerRating,
  'service': r.service.name,
  'vehicle_class': r.vehicleClass.name,
  'pickup': _place(r.pickup),
  'dropoff': _place(r.dropoff),
  'stop': r.stop == null ? null : _place(r.stop!),
  'pickup_lat': r.pickup.coord.latitude,
  'pickup_lng': r.pickup.coord.longitude,
  'dropoff_lat': r.dropoff.coord.latitude,
  'dropoff_lng': r.dropoff.coord.longitude,
  'asking_price': r.askingPrice,
  'recommended_price': r.recommendedPrice,
  'price_raises': r.priceRaises,
  'distance_km': r.distanceKm,
  'duration_minutes': r.durationMinutes,
  'payment_method': r.paymentMethod.name,
  'passenger_count': r.passengerCount,
  'comment': r.comment,
  'options': r.options.map((o) => o.name).toList(),
  'status': r.status.name,
  'created_at': _iso(r.createdAt),
  'route_geometry': r.routeGeometry?.map(coordToJson).toList(),
};

/// The passenger's own updates: raising the fare, or calling the ride off.
Map<String, dynamic> ridePassengerPatch(Ride r) => {
  'asking_price': r.askingPrice,
  'price_raises': r.priceRaises,
  'status': r.status.name,
  'cancelled_at': _iso(r.cancelledAt),
  'cancelled_by': r.cancelledBy?.name,
  'cancel_reason': r.cancelReason,
  'rating_by_passenger': r.ratingByPassenger?.toJson(),
  'tip': r.tip,
};

/// The driver's own updates: where they are and how far along the trip is.
Map<String, dynamic> rideDriverPatch(Ride r) => {
  'status': r.status.name,
  'driver_lat': r.driverCoord?.latitude,
  'driver_lng': r.driverCoord?.longitude,
  'driver_bearing': r.driverBearing,
  'arrived_at': _iso(r.arrivedAt),
  'started_at': _iso(r.startedAt),
  'completed_at': _iso(r.completedAt),
  'cancelled_at': _iso(r.cancelledAt),
  'cancelled_by': r.cancelledBy?.name,
  'cancel_reason': r.cancelReason,
  'rating_by_driver': r.ratingByDriver?.toJson(),
};

Ride rideFromRow(Map<String, dynamic> row) => Ride(
  id: row['id'] as String,
  passengerId: row['passenger_id'] as String,
  passengerName: row['passenger_name'] as String,
  passengerAvatarColor: row['passenger_avatar_color'] as int,
  passengerRating: _maybeDouble(row['passenger_rating']) ?? 5,
  service: _enum(ServiceType.values, row['service'], ServiceType.city),
  vehicleClass: _enum(
    VehicleClass.values,
    row['vehicle_class'],
    VehicleClass.economy,
  ),
  pickup: _placeFrom(row['pickup']),
  dropoff: _placeFrom(row['dropoff']),
  stop: row['stop'] == null ? null : _placeFrom(row['stop']),
  askingPrice: row['asking_price'] as int,
  finalPrice: row['final_price'] as int?,
  recommendedPrice: row['recommended_price'] as int,
  distanceKm: _double(row['distance_km']),
  durationMinutes: row['duration_minutes'] as int,
  paymentMethod: _enum(
    PaymentMethod.values,
    row['payment_method'],
    PaymentMethod.cash,
  ),
  passengerCount: row['passenger_count'] as int? ?? 1,
  comment: row['comment'] as String?,
  options: ((row['options'] as List?) ?? const [])
      .map((o) => _enum(RideOption.values, o, RideOption.luggage))
      .toList(),
  status: _enum(RideStatus.values, row['status'], RideStatus.searching),
  createdAt: _time(row['created_at'])!,
  updatedAt: _time(row['updated_at']) ?? _time(row['created_at'])!,
  priceRaises: row['price_raises'] as int? ?? 0,
  driverId: row['driver_id'] as String?,
  driverName: row['driver_name'] as String?,
  driverAvatarColor: row['driver_avatar_color'] as int?,
  driverRating: _maybeDouble(row['driver_rating']),
  driverVehicle: row['driver_vehicle'] == null
      ? null
      : Vehicle.fromJson(
          (row['driver_vehicle'] as Map).cast<String, dynamic>(),
        ),
  driverCoord: _coord(row['driver_lat'], row['driver_lng']),
  driverBearing: _maybeDouble(row['driver_bearing']),
  acceptedAt: _time(row['accepted_at']),
  arrivedAt: _time(row['arrived_at']),
  startedAt: _time(row['started_at']),
  completedAt: _time(row['completed_at']),
  cancelledAt: _time(row['cancelled_at']),
  cancelledBy: row['cancelled_by'] == null
      ? null
      : _enum(CancelledBy.values, row['cancelled_by'], CancelledBy.system),
  cancelReason: row['cancel_reason'] as String?,
  routeGeometry: (row['route_geometry'] as List?)
      ?.map((c) => (c as Map).cast<String, dynamic>())
      .map((c) => LatLng(_double(c['lat']), _double(c['lng'])))
      .toList(),
  ratingByPassenger: row['rating_by_passenger'] == null
      ? null
      : RideRating.fromJson(
          (row['rating_by_passenger'] as Map).cast<String, dynamic>(),
        ),
  ratingByDriver: row['rating_by_driver'] == null
      ? null
      : RideRating.fromJson(
          (row['rating_by_driver'] as Map).cast<String, dynamic>(),
        ),
  tip: row['tip'] as int?,
);

// ---------------------------------------------------------------------------
// Offers
// ---------------------------------------------------------------------------

Map<String, dynamic> offerToInsert(Offer o) => {
  'id': o.id,
  'ride_id': o.rideId,
  'driver_id': o.driverId,
  'driver_name': o.driverName,
  'driver_avatar_color': o.driverAvatarColor,
  'driver_rating': o.driverRating,
  'driver_rides_given': o.driverRidesGiven,
  'vehicle': o.vehicle.toJson(),
  'price': o.price,
  'eta_minutes': o.etaMinutes,
  'distance_km': o.distanceKm,
  'status': o.status.name,
  'matched_asking_price': o.matchedAskingPrice,
  'created_at': _iso(o.createdAt),
  'expires_at': _iso(o.expiresAt),
};

Offer offerFromRow(Map<String, dynamic> row) => Offer(
  id: row['id'] as String,
  rideId: row['ride_id'] as String,
  driverId: row['driver_id'] as String,
  driverName: row['driver_name'] as String,
  driverAvatarColor: row['driver_avatar_color'] as int,
  driverRating: _maybeDouble(row['driver_rating']) ?? 5,
  driverRidesGiven: row['driver_rides_given'] as int? ?? 0,
  vehicle: Vehicle.fromJson((row['vehicle'] as Map).cast<String, dynamic>()),
  price: row['price'] as int,
  etaMinutes: row['eta_minutes'] as int,
  distanceKm: _double(row['distance_km']),
  createdAt: _time(row['created_at'])!,
  expiresAt: _time(row['expires_at'])!,
  status: _enum(OfferStatus.values, row['status'], OfferStatus.pending),
  matchedAskingPrice: row['matched_asking_price'] as bool? ?? false,
);

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

/// [senderId] is passed separately: the model records which *side* sent a
/// message, which is what the chat bubbles need, while the database records
/// which *account* did, which is what the insert policy checks.
Map<String, dynamic> chatToInsert(ChatMessage m, String senderId) => {
  'id': m.id,
  'ride_id': m.rideId,
  'sender_id': senderId,
  'sender_role': m.from.name,
  'text': m.text,
  'read': m.read,
  'created_at': _iso(m.createdAt),
};

ChatMessage chatFromRow(Map<String, dynamic> row) => ChatMessage(
  id: row['id'] as String,
  rideId: row['ride_id'] as String,
  from: _enum(Role.values, row['sender_role'], Role.passenger),
  text: row['text'] as String,
  createdAt: _time(row['created_at'])!,
  read: row['read'] as bool? ?? false,
);

// ---------------------------------------------------------------------------
// Driver positions
// ---------------------------------------------------------------------------

Map<String, dynamic> driverLocationToRow({
  required String driverId,
  required LatLng coord,
  required double bearing,
  bool online = true,
}) => {
  'driver_id': driverId,
  'lat': coord.latitude,
  'lng': coord.longitude,
  'bearing': bearing,
  'online': online,
  'updated_at': _iso(DateTime.now()),
};

// ---------------------------------------------------------------------------
// Wallet
//
// Read-only: the ledger has a `select` policy and no other, so there is no
// insert shape to write. Money moves when the database settles a ride.
// ---------------------------------------------------------------------------

Txn walletTxnFromRow(Map<String, dynamic> row) => Txn(
  id: row['id'] as String,
  kind: _enum(TransactionKind.values, row['kind'], TransactionKind.ridePayment),
  amount: row['amount'] as int,
  description: row['description'] as String,
  createdAt: _time(row['created_at'])!,
  rideId: row['ride_id'] as String?,
);
