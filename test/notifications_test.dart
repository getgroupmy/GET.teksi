import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/bus.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'marketplace_test.dart' show buildRide;

/// The bell was full against the simulated marketplace and silent against a
/// real one. Bots run in this process and go through the local path, which
/// notified; a real counterparty arrives over the bus, which did not. So these
/// are all about events that came from somebody else's device — and about the
/// backlog, which arrives the same way and must not ring at all.

const _car = Vehicle(
  make: 'Perodua',
  model: 'Myvi',
  year: 2022,
  color: 'White',
  plate: 'WXY 1234',
  vehicleClass: VehicleClass.economy,
  seats: 4,
);

Offer _bid(Ride ride, {OfferStatus status = OfferStatus.pending}) => Offer(
  id: 'offer-1',
  rideId: ride.id,
  driverId: 'driver-1',
  driverName: 'Ravi',
  driverAvatarColor: 0,
  driverRating: 4.9,
  driverRidesGiven: 320,
  vehicle: _car,
  price: ride.askingPrice,
  etaMinutes: 4,
  distanceKm: 1.1,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(seconds: 90)),
  status: status,
  matchedAskingPrice: true,
);

void main() {
  late SessionStore session;
  late RidesStore rides;

  Future<void> deliver(BusEvent event) async {
    bus.publish(event);
    await Future<void>.delayed(Duration.zero);
  }

  /// Signs in as [id] and returns a ride they are the passenger on, already
  /// known to this device so a later change is a transition rather than news.
  Future<Ride> knownRide({String as = 'passenger-1'}) async {
    session.signIn('+60111111111', name: 'Aisyah', id: as);
    final ride = buildRide(passengerId: as);
    await deliver(RidePublished(ride));
    return ride;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    rides = RidesStore(session);
  });

  tearDown(() => rides.dispose());

  test('a driver bidding on my order rings the bell', () async {
    final ride = await knownRide();
    await deliver(OfferCreated(_bid(ride)));

    expect(rides.notifications, hasLength(1));
    expect(rides.notifications.first.title, contains('Ravi'));
    expect(rides.notifications.first.rideId, ride.id);
  });

  test('the same bid arriving twice rings once', () async {
    final ride = await knownRide();
    final offer = _bid(ride);
    await deliver(OfferCreated(offer));
    await deliver(OfferCreated(offer));

    expect(rides.notifications, hasLength(1));
  });

  test('a bid on somebody else\'s order is not my business', () async {
    session.signIn('+60111111111', name: 'Aisyah', id: 'passenger-1');
    final theirs = buildRide(passengerId: 'someone-else');
    await deliver(RidePublished(theirs));
    await deliver(OfferCreated(_bid(theirs)));

    expect(rides.notifications, isEmpty);
  });

  test('the passenger hears each step the driver takes', () async {
    final ride = await knownRide();
    var current = ride;

    for (final status in [
      RideStatus.accepted,
      RideStatus.arriving,
      RideStatus.inProgress,
      RideStatus.completed,
    ]) {
      current = current.copyWith(
        status: status,
        driverId: 'driver-1',
        driverName: 'Ravi',
        updatedAt: current.updatedAt.add(const Duration(minutes: 1)),
      );
      await deliver(RideUpdated(current));
    }

    expect(rides.notifications, hasLength(4));
    expect(rides.notifications.first.title, 'Trip completed');
    expect(rides.notifications.last.title, 'Driver on the way');
  });

  test('a driver learns their bid won', () async {
    session.signIn('+60123456789', name: 'Ravi', id: 'driver-1');
    final ride = buildRide(passengerId: 'passenger-1');
    await deliver(RidePublished(ride));
    await deliver(OfferCreated(_bid(ride)));
    final mine = _bid(ride);
    await deliver(
      OfferUpdated(
        Offer(
          id: mine.id,
          rideId: mine.rideId,
          driverId: mine.driverId,
          driverName: mine.driverName,
          driverAvatarColor: mine.driverAvatarColor,
          driverRating: mine.driverRating,
          driverRidesGiven: mine.driverRidesGiven,
          vehicle: mine.vehicle,
          price: mine.price,
          etaMinutes: mine.etaMinutes,
          distanceKm: mine.distanceKm,
          createdAt: mine.createdAt,
          expiresAt: mine.expiresAt,
          status: OfferStatus.accepted,
          matchedAskingPrice: mine.matchedAskingPrice,
        ),
      ),
    );

    expect(rides.notifications.first.title, 'Your offer was accepted');
  });

  test('the other side cancelling is announced', () async {
    final ride = await knownRide();
    await deliver(
      RideCancelled(ride.id, CancelledBy.driver, 'Vehicle problem'),
    );

    expect(rides.notifications.first.title, 'Driver cancelled');
    expect(rides.notifications.first.body, 'Vehicle problem');
  });

  test('a backlog is history and rings nothing', () async {
    // The trap this separation exists for: a fresh sign-in replays what was
    // already true, and every one of those rows would otherwise be an alert
    // about something that finished days ago.
    session.signIn('+60111111111', name: 'Aisyah', id: 'passenger-1');
    final ride = buildRide(passengerId: 'passenger-1');
    final finished = ride.copyWith(
      status: RideStatus.completed,
      driverId: 'driver-1',
      updatedAt: ride.updatedAt.add(const Duration(hours: 3)),
    );

    await deliver(
      BacklogLoaded([
        RidePublished(ride),
        RidePublished(finished),
        OfferCreated(_bid(ride)),
      ]),
    );

    expect(rides.notifications, isEmpty);
    // But the state still landed, which is the whole point of the backlog.
    expect(rides.rides[ride.id]!.status, RideStatus.completed);
    expect(rides.offersForRide(ride.id), hasLength(1));
  });

  test('news after a backlog still rings', () async {
    session.signIn('+60111111111', name: 'Aisyah', id: 'passenger-1');
    final ride = buildRide(passengerId: 'passenger-1');
    await deliver(BacklogLoaded([RidePublished(ride)]));
    expect(rides.notifications, isEmpty);

    await deliver(OfferCreated(_bid(ride)));

    expect(rides.notifications, hasLength(1));
  });
}
