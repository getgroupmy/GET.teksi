import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/bus.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'marketplace_test.dart' show buildRide;

/// Realtime carries changes, so a device that connects late has to be told what
/// was already true. The transport reads the current rows and replays them as
/// ordinary events — which is only safe if replaying them is idempotent and
/// cannot overwrite something fresher the device already has. That is what
/// these are about: not the reading, which needs a server, but the replaying,
/// which is where a backlog does damage if it is wrong.

void main() {
  late SessionStore session;
  late RidesStore rides;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    session.signIn('+60111111111', name: 'Passenger', id: 'passenger-1');
    rides = RidesStore(session);
  });

  tearDown(() => rides.dispose());

  /// Events arrive through the bus exactly as the transport sends them.
  Future<void> deliver(List<BusEvent> events) async {
    for (final e in events) {
      bus.publish(e);
    }
    await Future<void>.delayed(Duration.zero);
  }

  test('a backlog fills an empty device', () async {
    final ride = buildRide(passengerId: 'someone-else');
    await deliver([RidePublished(ride)]);

    expect(rides.rides[ride.id], isNotNull);
    expect(rides.rides[ride.id]!.status, RideStatus.searching);
  });

  test('replaying the same backlog changes nothing', () async {
    final ride = buildRide(passengerId: 'passenger-1');
    final offer = _offerOn(ride, 'driver-1');
    final message = _messageOn(ride);

    await deliver([
      RidePublished(ride),
      OfferCreated(offer),
      ChatSent(message),
    ]);
    final ridesAfterFirst = rides.rides.length;

    await deliver([
      RidePublished(ride),
      OfferCreated(offer),
      ChatSent(message),
    ]);

    expect(rides.rides, hasLength(ridesAfterFirst));
    expect(rides.offersForRide(ride.id), hasLength(1));
    expect(rides.chatFor(ride.id), hasLength(1));
  });

  test('a stale backlog row does not undo a newer local one', () async {
    // The case that would actually hurt: reconnecting mid-trip and having the
    // server's older snapshot walk the ride backwards to `searching`.
    final published = buildRide(passengerId: 'passenger-1');
    await deliver([RidePublished(published)]);

    final movedOn = published.copyWith(
      status: RideStatus.inProgress,
      updatedAt: published.updatedAt.add(const Duration(minutes: 5)),
    );
    await deliver([RideUpdated(movedOn)]);

    // The backlog arrives late, carrying the earlier state.
    await deliver([RidePublished(published)]);

    expect(rides.rides[published.id]!.status, RideStatus.inProgress);
  });

  test('a fresher backlog row wins over what the device had', () async {
    final published = buildRide(passengerId: 'passenger-1');
    await deliver([RidePublished(published)]);

    final newer = published.copyWith(
      status: RideStatus.completed,
      updatedAt: published.updatedAt.add(const Duration(minutes: 20)),
    );
    await deliver([RidePublished(newer)]);

    expect(rides.rides[published.id]!.status, RideStatus.completed);
  });

  test('a ride that ended cancelled arrives cancelled, without an event', () async {
    // The transport replays a cancelled ride as RidePublished on purpose:
    // RideCancelled is the moment of cancelling, and replaying that would greet
    // a reinstalling user with a dialog about a ride called off last week. The
    // status still has to land.
    final cancelled = buildRide(
      passengerId: 'passenger-1',
      status: RideStatus.cancelled,
    );
    await deliver([RidePublished(cancelled)]);

    expect(rides.rides[cancelled.id]!.status, RideStatus.cancelled);
  });

  test(
    'a backlog restores the ride the passenger is in the middle of',
    () async {
      // A second device, or a reinstall. Local persistence is what survives a
      // cold start and a fresh device has none, so without the backlog the
      // passenger is mid-trip with an app that shows no trip.
      final live = buildRide(passengerId: 'passenger-1')
          .copyWith(status: RideStatus.inProgress, driverId: 'driver-1');
      await deliver([RidePublished(live)]);

      expect(rides.activeRideFor('passenger-1', Role.passenger), isNotNull);
    },
  );
}

Offer _offerOn(Ride ride, String driverId) => Offer(
  id: 'offer-1',
  rideId: ride.id,
  driverId: driverId,
  driverName: 'Driver',
  driverAvatarColor: 0,
  driverRating: 4.9,
  driverRidesGiven: 100,
  vehicle: const Vehicle(
    make: 'Perodua',
    model: 'Myvi',
    year: 2022,
    color: 'White',
    plate: 'WXY 1234',
    vehicleClass: VehicleClass.economy,
    seats: 4,
  ),
  price: ride.askingPrice,
  etaMinutes: 4,
  distanceKm: 1.2,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(seconds: 90)),
  status: OfferStatus.pending,
  matchedAskingPrice: true,
);

ChatMessage _messageOn(Ride ride) => ChatMessage(
  id: 'message-1',
  rideId: ride.id,
  from: Role.driver,
  text: 'On my way',
  createdAt: DateTime.now(),
  read: false,
);
