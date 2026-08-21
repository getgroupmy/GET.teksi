import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/bus.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'marketplace_test.dart' show buildRide;

/// The in-app centre is a screen you have to visit, and a driver waiting for
/// orders is looking at the road. These are about the second half — which of
/// the things the bell records are also worth interrupting someone for.
///
/// The distinction is who caused it. Anything the other participant did is
/// news; anything this device's own user just tapped is a receipt, and a phone
/// that buzzes half a second after your own thumb is a phone people turn the
/// notifications off on.

const _car = Vehicle(
  make: 'Perodua',
  model: 'Myvi',
  year: 2022,
  color: 'White',
  plate: 'WXY 1234',
  vehicleClass: VehicleClass.economy,
  seats: 4,
);

Offer _bid(Ride ride) => Offer(
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
  status: OfferStatus.pending,
  matchedAskingPrice: true,
);

void main() {
  late SessionStore session;
  late RidesStore rides;

  /// Everything handed to the platform's notification manager.
  late List<AppNotification> alerted;

  Future<void> deliver(BusEvent event) async {
    bus.publish(event);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    alerted = [];
    rides = RidesStore(session, onAlert: alerted.add);
    session.signIn('+60111111111', name: 'Aisyah', id: 'passenger-1');
  });

  tearDown(() => rides.dispose());

  /// A ride this device already knows about, so a later change reads as a
  /// transition rather than as news it has never seen.
  Future<Ride> knownRide() async {
    final ride = buildRide(passengerId: 'passenger-1');
    await deliver(RidePublished(ride));
    return ride;
  }

  test(
    'a bid from another phone reaches the tray, not just the centre',
    () async {
      final ride = await knownRide();
      await deliver(OfferCreated(_bid(ride)));

      expect(alerted, hasLength(1));
      // The same object both places: whatever the centre shows is what the
      // banner says, with no second rendering to drift out of step.
      expect(identical(alerted.single, rides.notifications.first), isTrue);
      expect(alerted.single.title, contains('Ravi'));
      expect(alerted.single.rideId, ride.id);
    },
  );

  test('every step the driver takes buzzes once', () async {
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

    expect(alerted.map((n) => n.title), [
      'Driver on the way',
      'Your driver is arriving',
      'Trip started',
      'Trip completed',
    ]);
  });

  test('raising my own price is a receipt, not an interruption', () async {
    final ride = await knownRide();
    rides.raisePrice(ride.id, ride.askingPrice + 300);
    await Future<void>.delayed(Duration.zero);

    // Recorded, because the centre is a log of what happened to the order...
    expect(rides.notifications.map((n) => n.title), contains('Price raised'));
    // ...but the thumb that raised it is still on the screen.
    expect(alerted, isEmpty);
  });

  test('cancelling my own ride does not buzz my own phone', () async {
    final ride = await knownRide();
    rides.cancelRide(ride.id, CancelledBy.passenger, 'Changed my mind');
    await Future<void>.delayed(Duration.zero);

    expect(rides.notifications.first.title, 'Ride cancelled');
    expect(alerted, isEmpty);
  });

  test('the other side cancelling does buzz', () async {
    // The counterpart to the test above, and the reason that one cannot simply
    // drop the notification: the same words mean something very different
    // depending on which phone the tap happened on.
    final ride = await knownRide();
    await deliver(
      RideCancelled(ride.id, CancelledBy.driver, 'Vehicle problem'),
    );

    expect(alerted, hasLength(1));
    expect(alerted.single.title, 'Driver cancelled');
  });

  test('a backlog does not set every phone in the country off', () async {
    // A fresh sign-in replays what was already true. Through the ordinary path
    // that is a burst of banners about trips that finished days ago — the one
    // failure mode that gets an app's notifications disabled for good.
    final ride = buildRide(passengerId: 'passenger-1');
    await deliver(
      BacklogLoaded([
        RidePublished(ride),
        RidePublished(
          ride.copyWith(
            status: RideStatus.completed,
            driverId: 'driver-1',
            updatedAt: ride.updatedAt.add(const Duration(hours: 3)),
          ),
        ),
        OfferCreated(_bid(ride)),
      ]),
    );

    expect(alerted, isEmpty);
    expect(rides.notifications, isEmpty);
    // The state still landed; only the noise was dropped.
    expect(rides.rides[ride.id]!.status, RideStatus.completed);
  });

  test('news after a backlog still buzzes', () async {
    final ride = buildRide(passengerId: 'passenger-1');
    await deliver(BacklogLoaded([RidePublished(ride)]));
    expect(alerted, isEmpty);

    await deliver(OfferCreated(_bid(ride)));

    expect(alerted, hasLength(1));
  });

  test('a store with nowhere to send alerts still runs', () async {
    // The default on every platform without a notification manager, and in
    // this suite. A missing notifier is a quieter app, not a broken one.
    final quiet = RidesStore(session);
    addTearDown(quiet.dispose);
    final ride = buildRide(passengerId: 'passenger-1');
    bus.publish(RidePublished(ride));
    await Future<void>.delayed(Duration.zero);
    bus.publish(OfferCreated(_bid(ride)));
    await Future<void>.delayed(Duration.zero);

    expect(quiet.notifications, hasLength(1));
  });

  test('the silent notifier accepts everything and does nothing', () async {
    const notifier = SilentNotifier();
    await notifier.requestPermission();
    await notifier.show(
      AppNotification(
        id: 'ntf-1',
        title: 'Trip completed',
        body: 'Rate your driver.',
        createdAt: DateTime.now(),
        read: false,
        kind: NotificationKind.ride,
      ),
    );
  });
}
