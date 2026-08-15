import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/services/pricing.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
const _car = Vehicle(
  make: 'Perodua',
  model: 'Myvi',
  year: 2022,
  color: 'White',
  plate: 'WXY 1234',
  vehicleClass: VehicleClass.economy,
  seats: 4,
);

Ride buildRide({
  required String passengerId,
  int askingPrice = 1500,
  RideStatus status = RideStatus.searching,
}) {
  final now = DateTime.now();
  return Ride(
    id: uid('ride'),
    passengerId: passengerId,
    passengerName: 'Rider',
    passengerAvatarColor: 0xFFC1F11D,
    passengerRating: 4.8,
    service: ServiceType.city,
    vehicleClass: VehicleClass.economy,
    pickup: _pickup,
    dropoff: _dropoff,
    askingPrice: askingPrice,
    recommendedPrice: 1500,
    distanceKm: 6.2,
    durationMinutes: 18,
    paymentMethod: PaymentMethod.cash,
    passengerCount: 1,
    options: const [],
    status: status,
    createdAt: now,
    updatedAt: now,
    priceRaises: 0,
  );
}

Offer buildOffer({
  required String rideId,
  required String driverId,
  required int price,
  Duration ttl = offerTtl,
  bool matchedAsking = false,
}) {
  return Offer(
    id: uid('ofr'),
    rideId: rideId,
    driverId: driverId,
    driverName: 'Driver $driverId',
    driverAvatarColor: 0xFF22D3EE,
    driverRating: 4.9,
    driverRidesGiven: 800,
    vehicle: _car,
    price: price,
    etaMinutes: 4,
    distanceKm: 1.2,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(ttl),
    status: OfferStatus.pending,
    matchedAskingPrice: matchedAsking,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore session;
  late RidesStore rides;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    session.signIn('60123456789', name: 'Test Rider');
    rides = RidesStore(session);
  });

  tearDown(() {
    rides.dispose();
  });

  group('publishing an order', () {
    test('puts the ride on the market with route geometry', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      expect(rides.rides[ride.id]!.status, RideStatus.searching);
      expect(ride.routeGeometry, isNotNull);
      expect(ride.routeGeometry!.length, greaterThan(2));
    });

    test('surfaces it to other drivers but not to the passenger', () {
      final me = session.requireUser.id;
      final ride = rides.publishRide(buildRide(passengerId: me));
      // A driver sees it…
      expect(
        rides.openOrders('some-other-driver').map((r) => r.id),
        contains(ride.id),
      );
      // …but you can never drive your own order.
      expect(rides.openOrders(me), isEmpty);
    });
  });

  group('bidding', () {
    test('accepts a bid and records the agreed price on the ride', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      final offer = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1700);
      rides.createOffer(offer);

      expect(rides.pendingOffersForRide(ride.id).length, 1);
      rides.acceptOffer(offer.id);

      final updated = rides.rides[ride.id]!;
      expect(updated.status, RideStatus.accepted);
      expect(updated.finalPrice, 1700);
      expect(updated.driverId, 'drv1');
      expect(updated.fare, 1700);
    });

    test('accepting one bid declines every other bid on that ride', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      final a = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1500);
      final b = buildOffer(rideId: ride.id, driverId: 'drv2', price: 1600);
      final c = buildOffer(rideId: ride.id, driverId: 'drv3', price: 1800);
      for (final o in [a, b, c]) {
        rides.createOffer(o);
      }

      rides.acceptOffer(b.id);

      expect(rides.offers[b.id]!.status, OfferStatus.accepted);
      expect(rides.offers[a.id]!.status, OfferStatus.declined);
      expect(rides.offers[c.id]!.status, OfferStatus.declined);
      expect(rides.pendingOffersForRide(ride.id), isEmpty);
    });

    test('sorts bids cheapest first', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      rides.createOffer(
        buildOffer(rideId: ride.id, driverId: 'a', price: 2200),
      );
      rides.createOffer(
        buildOffer(rideId: ride.id, driverId: 'b', price: 1500),
      );
      rides.createOffer(
        buildOffer(rideId: ride.id, driverId: 'c', price: 1900),
      );

      expect(
        rides.offersForRide(ride.id).map((o) => o.price),
        orderedEquals([1500, 1900, 2200]),
      );
    });

    test('refuses new bids once the order is off the market', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      final first = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1500);
      rides.createOffer(first);
      rides.acceptOffer(first.id);

      rides.createOffer(
        buildOffer(rideId: ride.id, driverId: 'drv2', price: 1400),
      );
      expect(rides.offersForRide(ride.id).length, 1);
    });

    test('a withdrawn bid stops counting as pending', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      final offer = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1500);
      rides.createOffer(offer);

      expect(rides.myPendingOfferFor(ride.id, 'drv1'), isNotNull);
      rides.withdrawOffer(offer.id);
      expect(rides.myPendingOfferFor(ride.id, 'drv1'), isNull);
    });
  });

  group('raising the price', () {
    test('records each raise and only applies while searching', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      rides.raisePrice(ride.id, 1800);
      expect(rides.rides[ride.id]!.askingPrice, 1800);
      expect(rides.rides[ride.id]!.priceRaises, 1);

      final offer = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1800);
      rides.createOffer(offer);
      rides.acceptOffer(offer.id);

      // Once matched, the price is settled.
      rides.raisePrice(ride.id, 2500);
      expect(rides.rides[ride.id]!.askingPrice, 1800);
    });
  });

  group('cancellation', () {
    test('voids every pending bid on the order', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      final offer = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1500);
      rides.createOffer(offer);

      rides.cancelRide(ride.id, CancelledBy.passenger, 'Changed my mind');

      expect(rides.rides[ride.id]!.status, RideStatus.cancelled);
      expect(rides.rides[ride.id]!.cancelReason, 'Changed my mind');
      expect(rides.offers[offer.id]!.status, OfferStatus.declined);
    });

    test('is a no-op on a completed ride', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      rides.setRideStatus(ride.id, RideStatus.completed);
      rides.cancelRide(ride.id, CancelledBy.driver);
      expect(rides.rides[ride.id]!.status, RideStatus.completed);
    });
  });

  group('completing a trip', () {
    test('debits the passenger and files a receipt', () {
      final me = session.requireUser.id;
      final ride = rides.publishRide(buildRide(passengerId: me));
      final offer = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1700);
      rides.createOffer(offer);
      rides.acceptOffer(offer.id);

      final tripsBefore = session.requireUser.ridesTaken;
      rides.completeRide(ride.id);

      expect(rides.rides[ride.id]!.status, RideStatus.completed);
      expect(session.requireUser.ridesTaken, tripsBefore + 1);
      expect(rides.transactions.first.kind, TransactionKind.ridePayment);
      expect(rides.transactions.first.amount, -1700);
    });

    test('pays the driver the fare less commission', () {
      final me = session.requireUser.id;
      session.becomeDriver(_car);
      final ride = rides.publishRide(
        buildRide(passengerId: 'bp_someone', askingPrice: 2000),
      );
      final offer = buildOffer(rideId: ride.id, driverId: me, price: 2000);
      rides.createOffer(offer);
      rides.acceptOffer(offer.id);

      final walletBefore = session.requireUser.walletBalance;
      rides.completeRide(ride.id);

      final expected = driverNet(2000);
      expect(session.requireUser.walletBalance, walletBefore + expected);
      expect(session.requireUser.driverProfile!.earnings, expected);
      expect(rides.transactions.first.amount, expected);
    });
  });

  group('sweep', () {
    test('expires bids past their TTL', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      final stale = buildOffer(
        rideId: ride.id,
        driverId: 'drv1',
        price: 1500,
        ttl: const Duration(milliseconds: -1),
      );
      rides.createOffer(stale);

      rides.sweep();
      expect(rides.offers[stale.id]!.status, OfferStatus.expired);
      expect(rides.pendingOffersForRide(ride.id), isEmpty);
    });
  });

  group('active ride and rating queue', () {
    test('tracks the live ride for each side', () {
      final me = session.requireUser.id;
      final ride = rides.publishRide(buildRide(passengerId: me));
      expect(rides.activeRideFor(me, Role.passenger)?.id, ride.id);
      expect(rides.activeRideFor(me, Role.driver), isNull);
    });

    test('queues a completed ride for rating, then clears it', () {
      final me = session.requireUser.id;
      final ride = rides.publishRide(buildRide(passengerId: me));
      final offer = buildOffer(rideId: ride.id, driverId: 'drv1', price: 1500);
      rides.createOffer(offer);
      rides.acceptOffer(offer.id);
      rides.completeRide(ride.id);

      expect(rides.rideAwaitingRating(me, Role.passenger)?.id, ride.id);

      rides.rateRide(
        ride.id,
        Role.passenger,
        RideRating(stars: 5, tags: const ['Polite'], createdAt: DateTime.now()),
      );

      expect(rides.rideAwaitingRating(me, Role.passenger), isNull);
      expect(rides.rides[ride.id]!.ratingByPassenger!.stars, 5);
    });

    test('a completed ride leaves the active slot and enters history', () {
      final me = session.requireUser.id;
      final ride = rides.publishRide(buildRide(passengerId: me));
      rides.setRideStatus(ride.id, RideStatus.completed);

      expect(rides.activeRideFor(me, Role.passenger), isNull);
      expect(
        rides.historyFor(me, Role.passenger).map((r) => r.id),
        contains(ride.id),
      );
    });
  });

  group('chat', () {
    test('counts only the other side’s unread messages', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      rides.sendMessage(ride.id, Role.driver, 'On my way');
      rides.sendMessage(ride.id, Role.passenger, 'Thanks!');

      expect(rides.unreadChat(ride.id, Role.passenger), 1);
      expect(rides.unreadChat(ride.id, Role.driver), 1);

      rides.markChatRead(ride.id, Role.passenger);
      expect(rides.unreadChat(ride.id, Role.passenger), 0);
      expect(rides.unreadChat(ride.id, Role.driver), 1);
    });

    test('ignores empty messages', () {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      rides.sendMessage(ride.id, Role.passenger, '   ');
      expect(rides.chatFor(ride.id), isEmpty);
    });
  });

  group('persistence', () {
    test('a ride survives a store restart', () async {
      final ride = rides.publishRide(
        buildRide(passengerId: session.requireUser.id),
      );
      // Rebuild from the same backing store, as a cold app start would.
      final reopened = RidesStore(session);
      expect(reopened.rides[ride.id]?.id, ride.id);
      expect(reopened.rides[ride.id]?.askingPrice, ride.askingPrice);
      reopened.dispose();
    });
  });
}
