import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/rows.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:latlong2/latlong.dart';

/// The mapping between the domain models and Postgres rows is the seam where
/// a schema change goes wrong quietly: a dropped field does not fail to
/// compile, it just arrives as null in someone's live ride. These tests pin
/// the shape from both directions.

const _klcc = LatLng(3.1578, 101.7123);
const _midValley = LatLng(3.1177, 101.6771);

Place _place(String name, LatLng at) =>
    Place(id: uid('pl'), name: name, address: '$name, KL', coord: at);

final _vehicle = const Vehicle(
  make: 'Perodua',
  model: 'Bezza',
  year: 2021,
  color: 'Silver',
  plate: 'WXY 1234',
  vehicleClass: VehicleClass.economy,
  seats: 4,
);

Ride _ride({
  RideStatus status = RideStatus.searching,
  bool withDriver = false,
}) {
  final now = DateTime.now();
  return Ride(
    id: uuid4(),
    passengerId: uuid4(),
    passengerName: 'Aisyah',
    passengerAvatarColor: 0xFF4CAF50,
    passengerRating: 4.8,
    service: ServiceType.city,
    vehicleClass: VehicleClass.comfort,
    pickup: _place('KLCC', _klcc),
    dropoff: _place('Mid Valley', _midValley),
    askingPrice: 1850,
    recommendedPrice: 2000,
    distanceKm: 8.4,
    durationMinutes: 22,
    paymentMethod: PaymentMethod.wallet,
    passengerCount: 2,
    options: const [RideOption.luggage, RideOption.airCon],
    status: status,
    createdAt: now.subtract(const Duration(minutes: 4)),
    updatedAt: now,
    priceRaises: 1,
    comment: 'Tower 2 entrance',
    routeGeometry: const [_klcc, _midValley],
    driverId: withDriver ? uuid4() : null,
    driverName: withDriver ? 'Ravi' : null,
    driverAvatarColor: withDriver ? 0xFF2196F3 : null,
    driverRating: withDriver ? 4.9 : null,
    driverVehicle: withDriver ? _vehicle : null,
    driverCoord: withDriver ? _klcc : null,
    driverBearing: withDriver ? 137.5 : null,
    finalPrice: withDriver ? 1900 : null,
  );
}

Offer _offer() => Offer(
  id: uuid4(),
  rideId: uuid4(),
  driverId: uuid4(),
  driverName: 'Ravi',
  driverAvatarColor: 0xFF2196F3,
  driverRating: 4.9,
  driverRidesGiven: 1204,
  vehicle: _vehicle,
  price: 1900,
  etaMinutes: 6,
  distanceKm: 2.3,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(seconds: 90)),
  status: OfferStatus.pending,
  matchedAskingPrice: false,
);

/// PostgREST hands back JSON, so a row read from the database is never the
/// literal map we sent: `timestamptz` becomes an ISO string, `jsonb` becomes a
/// plain map, and the server fills in its own defaults. This models that trip.
Map<String, dynamic> _asReadBack(
  Map<String, dynamic> insert, {
  Map<String, dynamic> serverFields = const {},
}) => {...insert, ...serverFields};

void main() {
  group('uuid4', () {
    test('has the RFC 4122 shape and version', () {
      final id = uuid4();
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
        reason: '$id is not a well-formed v4 uuid',
      );
    });

    test('does not collide across a large batch', () {
      final ids = List.generate(5000, (_) => uuid4()).toSet();
      expect(ids.length, 5000);
    });
  });

  group('ride rows', () {
    test('survive a round trip through the insert shape', () {
      final ride = _ride();
      final back = rideFromRow(
        _asReadBack(
          rideToInsert(ride),
          serverFields: {
            'updated_at': ride.updatedAt.toUtc().toIso8601String(),
          },
        ),
      );

      expect(back.id, ride.id);
      expect(back.passengerId, ride.passengerId);
      expect(back.passengerName, ride.passengerName);
      expect(back.passengerRating, closeTo(ride.passengerRating, 0.001));
      expect(back.service, ride.service);
      expect(back.vehicleClass, ride.vehicleClass);
      expect(back.pickup.name, ride.pickup.name);
      expect(back.dropoff.coord.latitude, closeTo(_midValley.latitude, 1e-9));
      expect(back.askingPrice, ride.askingPrice);
      expect(back.recommendedPrice, ride.recommendedPrice);
      expect(back.distanceKm, closeTo(ride.distanceKm, 1e-9));
      expect(back.durationMinutes, ride.durationMinutes);
      expect(back.paymentMethod, ride.paymentMethod);
      expect(back.passengerCount, ride.passengerCount);
      expect(back.comment, ride.comment);
      expect(back.options, ride.options);
      expect(back.status, ride.status);
      expect(back.priceRaises, ride.priceRaises);
      expect(back.routeGeometry, isNotNull);
      expect(back.routeGeometry!.length, 2);
    });

    test('carry timestamps across the timezone boundary intact', () {
      final ride = _ride();
      final back = rideFromRow(
        _asReadBack(
          rideToInsert(ride),
          serverFields: {
            'updated_at': ride.updatedAt.toUtc().toIso8601String(),
          },
        ),
      );
      // Serialised as UTC, read back as local: the instant must not move, even
      // though the wall-clock reading does.
      expect(
        back.createdAt.difference(ride.createdAt).inMilliseconds.abs(),
        lessThan(1000),
      );
      expect(back.createdAt.isUtc, isFalse);
    });

    test('never send driver or settlement fields on insert', () {
      // The database rejects a passenger writing these. Sending them anyway
      // would turn every publish into a failed round trip.
      final insert = rideToInsert(_ride(withDriver: true));
      for (final forbidden in [
        'driver_id',
        'driver_name',
        'driver_rating',
        'driver_vehicle',
        'final_price',
        'accepted_at',
        'updated_at',
      ]) {
        expect(
          insert.containsKey(forbidden),
          isFalse,
          reason: '$forbidden is not the publishing client\'s to write',
        );
      }
    });

    test('read a driver-assigned row back in full', () {
      final ride = _ride(status: RideStatus.inProgress, withDriver: true);
      final row = _asReadBack(
        rideToInsert(ride),
        serverFields: {
          'updated_at': ride.updatedAt.toUtc().toIso8601String(),
          'status': RideStatus.inProgress.name,
          'driver_id': ride.driverId,
          'driver_name': ride.driverName,
          'driver_avatar_color': ride.driverAvatarColor,
          'driver_rating': ride.driverRating,
          'driver_vehicle': ride.driverVehicle!.toJson(),
          'driver_lat': ride.driverCoord!.latitude,
          'driver_lng': ride.driverCoord!.longitude,
          'driver_bearing': ride.driverBearing,
          'final_price': ride.finalPrice,
        },
      );
      final back = rideFromRow(row);

      expect(back.status, RideStatus.inProgress);
      expect(back.driverId, ride.driverId);
      expect(back.driverVehicle!.plate, _vehicle.plate);
      expect(back.driverCoord!.latitude, closeTo(_klcc.latitude, 1e-9));
      expect(back.driverBearing, closeTo(137.5, 1e-9));
      expect(back.finalPrice, 1900);
      expect(back.fare, 1900);
    });

    test('tolerate numeric columns arriving as strings', () {
      // PostgREST can widen `numeric` to text depending on client settings.
      // A live ride must degrade, not throw.
      final ride = _ride();
      final row = _asReadBack(
        rideToInsert(ride),
        serverFields: {
          'updated_at': ride.updatedAt.toUtc().toIso8601String(),
          'passenger_rating': '4.80',
          'driver_rating': '4.90',
        },
      );
      final back = rideFromRow(row);
      expect(back.passengerRating, closeTo(4.8, 0.001));
      expect(back.driverRating, closeTo(4.9, 0.001));
    });

    test('fall back rather than throw on an unknown enum value', () {
      // A server deployed ahead of this client must not crash it.
      final ride = _ride();
      final row = _asReadBack(
        rideToInsert(ride),
        serverFields: {
          'updated_at': ride.updatedAt.toUtc().toIso8601String(),
          'service': 'hyperloop',
          'status': 'teleporting',
        },
      );
      final back = rideFromRow(row);
      expect(back.service, ServiceType.city);
      expect(back.status, RideStatus.searching);
    });

    test('split the passenger and driver patches along the ownership line', () {
      final ride = _ride(status: RideStatus.arriving, withDriver: true);
      final passenger = ridePassengerPatch(ride);
      final driver = rideDriverPatch(ride);

      // The passenger owns the fare; the driver owns the trip's progress.
      expect(passenger.containsKey('asking_price'), isTrue);
      expect(driver.containsKey('asking_price'), isFalse);
      expect(driver.containsKey('driver_lat'), isTrue);
      expect(passenger.containsKey('driver_lat'), isFalse);
      // Neither side writes the settled fare — accept_offer() does.
      expect(passenger.containsKey('final_price'), isFalse);
      expect(driver.containsKey('final_price'), isFalse);
    });
  });

  group('offer rows', () {
    test('survive a round trip', () {
      final offer = _offer();
      final back = offerFromRow(_asReadBack(offerToInsert(offer)));

      expect(back.id, offer.id);
      expect(back.rideId, offer.rideId);
      expect(back.driverId, offer.driverId);
      expect(back.driverName, offer.driverName);
      expect(back.driverRating, closeTo(offer.driverRating, 0.001));
      expect(back.driverRidesGiven, offer.driverRidesGiven);
      expect(back.vehicle.plate, offer.vehicle.plate);
      expect(back.vehicle.vehicleClass, offer.vehicle.vehicleClass);
      expect(back.price, offer.price);
      expect(back.etaMinutes, offer.etaMinutes);
      expect(back.distanceKm, closeTo(offer.distanceKm, 1e-9));
      expect(back.status, offer.status);
      expect(back.matchedAskingPrice, offer.matchedAskingPrice);
    });

    test('preserve the expiry instant, which decides if a bid is live', () {
      final offer = _offer();
      final back = offerFromRow(_asReadBack(offerToInsert(offer)));
      expect(
        back.expiresAt.difference(offer.expiresAt).inMilliseconds.abs(),
        lessThan(1000),
      );
      expect(back.expiresAt.isAfter(DateTime.now()), isTrue);
    });
  });

  group('chat rows', () {
    test('round-trip, keeping the sender account out of the model', () {
      final senderId = uuid4();
      final message = ChatMessage(
        id: uuid4(),
        rideId: uuid4(),
        from: Role.driver,
        text: 'I am at the north entrance',
        createdAt: DateTime.now(),
        read: false,
      );
      final row = chatToInsert(message, senderId);
      expect(row['sender_id'], senderId);

      final back = chatFromRow(_asReadBack(row));
      expect(back.id, message.id);
      expect(back.rideId, message.rideId);
      expect(back.from, Role.driver);
      expect(back.text, message.text);
      expect(back.read, isFalse);
    });
  });

  group('driver location rows', () {
    test('carry the fields the map marker needs', () {
      final row = driverLocationToRow(
        driverId: 'd1',
        coord: _klcc,
        bearing: 42.5,
      );
      expect(row['driver_id'], 'd1');
      expect(row['lat'], closeTo(_klcc.latitude, 1e-9));
      expect(row['lng'], closeTo(_klcc.longitude, 1e-9));
      expect(row['bearing'], closeTo(42.5, 1e-9));
      expect(row['online'], isTrue);
    });
  });
}
