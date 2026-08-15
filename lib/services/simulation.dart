import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../core/formats.dart';
import '../core/geo.dart';
import '../core/storage.dart';
import '../data/fixtures.dart';
import '../data/places.dart';
import '../models/models.dart';
import '../state/rides.dart';
import '../state/session.dart';
import 'pricing.dart';

/// Makes the two-sided marketplace demonstrable on a single device: bot
/// drivers circulate on the map, bid on your orders and drive to you; bot
/// passengers post orders into the driver feed and answer your bids.
class MarketplaceSimulation {
  MarketplaceSimulation(this._session, this._rides);

  static const _tick = Duration(seconds: 1);
  static const _fleetSize = 9;
  static const _fleetRadiusKm = 3.5;

  final SessionStore _session;
  final RidesStore _rides;
  final _rng = math.Random();

  Timer? _timer;
  final List<NearbyDriver> _fleet = [];

  /// Where each bot is heading while idle (aimless city cruising).
  final Map<String, _BotTrip> _wander = {};

  /// Bot drivers currently fulfilling a ride, keyed by driver id.
  final Map<String, _BotTrip> _active = {};

  /// Rides a bot has already bid on, so nobody double-bids.
  final Map<String, Set<String>> _bidLog = {};

  /// Timestamps for staged behaviour (arrival dwell, decision delays).
  final Map<String, DateTime> _timers = {};

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    for (final d in _fleet) {
      _rides.removeNearbyDriver(d.id);
    }
    _fleet.clear();
    _wander.clear();
    _active.clear();
    _bidLog.clear();
    _timers.clear();
  }

  void dispose() => stop();

  T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  double _between(double min, double max) =>
      min + _rng.nextDouble() * (max - min);

  /* ---------------------------------------------------------------- */
  /* Fleet                                                            */
  /* ---------------------------------------------------------------- */

  String _randomPlate() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXY';
    String l() => letters[_rng.nextInt(letters.length)];
    return '${l()}${l()}${l()} ${1000 + _rng.nextInt(8999)}';
  }

  NearbyDriver _makeBot(LatLng center, int index) {
    final name = driverNames[index % driverNames.length];
    return NearbyDriver(
      id: uid('bot'),
      name: name,
      avatarColor: pickAvatarColor(name),
      rating: double.parse(_between(4.3, 5).toStringAsFixed(2)),
      ridesGiven: 120 + _rng.nextInt(4680),
      vehicle: _pick(vehicles).copyWith(plate: _randomPlate()),
      coord: randomPointNear(center, _fleetRadiusKm, _rng),
      bearing: _rng.nextDouble() * 360,
    );
  }

  void _ensureFleet(LatLng center) {
    if (_fleet.isEmpty) {
      for (var i = 0; i < _fleetSize; i++) {
        final bot = _makeBot(center, i);
        _fleet.add(bot);
        _rides.upsertNearbyDriver(bot);
      }
      return;
    }
    // Recycle bots that drifted far from the user so the map never empties.
    for (var i = 0; i < _fleet.length; i++) {
      final driver = _fleet[i];
      if (_active.containsKey(driver.id)) continue;
      if (haversineKm(driver.coord, center) > _fleetRadiusKm * 2.5) {
        _rides.removeNearbyDriver(driver.id);
        _wander.remove(driver.id);
        final replacement = _makeBot(center, i);
        _fleet[i] = replacement;
        _rides.upsertNearbyDriver(replacement);
      }
    }
  }

  void _wanderBot(NearbyDriver driver, LatLng center) {
    var trip = _wander[driver.id];
    if (trip == null || trip.progress >= 1) {
      final target = randomPointNear(center, _fleetRadiusKm, _rng);
      final path = syntheticRoute(driver.coord, target, _rng.nextInt(4));
      final km = pathLengthKm(path);
      // ~28 km/h of idle cruising, as a fraction of the path per tick.
      final speed = km > 0
          ? (28 / 3600) * (_tick.inMilliseconds / 1000) / km
          : 1.0;
      trip = _BotTrip(path, speed);
      _wander[driver.id] = trip;
    }
    trip.advance();
    final at = pointAlongPath(trip.path, trip.progress);
    driver.coord = at.coord;
    driver.bearing = at.bearing;
    _rides.upsertNearbyDriver(driver);
  }

  /* ---------------------------------------------------------------- */
  /* Bidding on the local passenger's order                           */
  /* ---------------------------------------------------------------- */

  void _botsBidOn(Ride ride) {
    final bidders = _bidLog.putIfAbsent(ride.id, () => <String>{});

    final ageMs = DateTime.now().difference(ride.createdAt).inMilliseconds;
    // Stagger arrivals: first bid ~3s in, then roughly one every 4s.
    final expected = math.min(_fleetSize, ((ageMs - 2500) ~/ 4000) + 1);
    if (expected <= bidders.length) return;

    final candidates =
        _fleet
            .where((d) => !bidders.contains(d.id) && !_active.containsKey(d.id))
            .where(
              (d) =>
                  ride.vehicleClass == VehicleClass.economy ||
                  d.vehicle.vehicleClass == ride.vehicleClass,
            )
            .map(
              (d) => (driver: d, km: haversineKm(d.coord, ride.pickup.coord)),
            )
            .where((c) => c.km < _fleetRadiusKm * 1.6)
            .toList()
          ..sort((a, b) => a.km.compareTo(b.km));

    if (candidates.isEmpty) return;
    final (driver: driver, km: km) = candidates.first;

    // How the bot judges the asking price against its own expectation.
    final expectedFare = recommendedPrice(
      distanceKm: ride.distanceKm,
      durationMinutes: ride.durationMinutes,
      vehicleClass: ride.vehicleClass,
      service: ride.service,
    );
    final askRatio = ride.askingPrice / expectedFare;

    // A really low ask simply gets ignored by most drivers.
    if (askRatio < 0.7 && _rng.nextDouble() < 0.75) {
      bidders.add(driver.id);
      return;
    }

    // Generous offers get taken as-is; low ones get a counter-bid.
    final takesAsking =
        askRatio >= 0.97 || (askRatio >= 0.88 && _rng.nextDouble() < 0.45);
    final price = takesAsking
        ? ride.askingPrice
        : roundFare(
            math.max(
              ride.askingPrice * 1.02,
              expectedFare * _between(1.05, 1.28),
            ),
          );

    bidders.add(driver.id);
    _rides.createOffer(
      Offer(
        id: uid('ofr'),
        rideId: ride.id,
        driverId: driver.id,
        driverName: driver.name,
        driverAvatarColor: driver.avatarColor,
        driverRating: driver.rating,
        driverRidesGiven: driver.ridesGiven,
        vehicle: driver.vehicle,
        price: price,
        etaMinutes: driveMinutes(km * 1.35),
        distanceKm: double.parse(km.toStringAsFixed(2)),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(offerTtl),
        status: OfferStatus.pending,
        matchedAskingPrice: takesAsking,
      ),
    );
  }

  /* ---------------------------------------------------------------- */
  /* Bot driver fulfilling an accepted ride                           */
  /* ---------------------------------------------------------------- */

  /// Bot trips are time-compressed: a real pickup leg of several minutes
  /// plays out in well under one, so the whole ride lifecycle stays watchable
  /// in a single sitting. Longer trips still take proportionally longer.
  Duration _pickupLeg(double km) =>
      Duration(milliseconds: (km * 12000).clamp(15000, 45000).round());

  Duration _mainLeg(double km) =>
      Duration(milliseconds: (15000 + km * 4000).clamp(30000, 75000).round());

  NearbyDriver? _botById(String id) {
    for (final d in _fleet) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _driveBot(Ride ride) {
    final driverId = ride.driverId!;
    final bot = _botById(driverId);
    final from = ride.driverCoord ?? bot?.coord ?? ride.pickup.coord;

    void place(PathPoint at) {
      _rides.setDriverLocation(driverId, at.coord, at.bearing);
      if (bot != null) {
        bot.coord = at.coord;
        bot.bearing = at.bearing;
        _rides.upsertNearbyDriver(bot);
      }
    }

    if (ride.status == RideStatus.accepted ||
        ride.status == RideStatus.arriving) {
      final trip = _active.putIfAbsent(driverId, () {
        final path = syntheticRoute(from, ride.pickup.coord, 1);
        return _BotTrip(
          path,
          _tick.inMilliseconds / _pickupLeg(pathLengthKm(path)).inMilliseconds,
        );
      });
      trip.advance();
      final at = pointAlongPath(trip.path, trip.progress);
      place(at);

      final remainingKm = haversineKm(at.coord, ride.pickup.coord);
      if (ride.status == RideStatus.accepted && remainingKm < 0.45) {
        _rides.setRideStatus(ride.id, RideStatus.arriving);
      }
      if (trip.progress >= 1 || remainingKm < 0.06) {
        _active.remove(driverId);
        _rides.setRideStatus(ride.id, RideStatus.waiting);
        _rides.sendMessage(
          ride.id,
          Role.driver,
          "I've arrived and I'm waiting outside.",
        );
        _rides.notify(
          kind: NotificationKind.ride,
          title: 'Your driver has arrived',
          body: '${ride.driverName} is waiting at ${ride.pickup.name}.',
          rideId: ride.id,
        );
        _timers['wait:${ride.id}'] = DateTime.now();
      }
      return;
    }

    if (ride.status == RideStatus.waiting) {
      // Give the passenger a beat to walk out, then pull away.
      final since = _timers['wait:${ride.id}'] ?? DateTime.now();
      if (DateTime.now().difference(since).inMilliseconds > 6000) {
        _timers.remove('wait:${ride.id}');
        _rides.setRideStatus(ride.id, RideStatus.inProgress);
        _rides.notify(
          kind: NotificationKind.ride,
          title: 'Trip started',
          body: 'On the way to ${ride.dropoff.name}.',
          rideId: ride.id,
        );
      }
      return;
    }

    if (ride.status == RideStatus.inProgress) {
      final trip = _active.putIfAbsent(driverId, () {
        final path = (ride.routeGeometry?.isNotEmpty ?? false)
            ? ride.routeGeometry!
            : syntheticRoute(ride.pickup.coord, ride.dropoff.coord, 3);
        return _BotTrip(
          path,
          _tick.inMilliseconds / _mainLeg(pathLengthKm(path)).inMilliseconds,
        );
      });
      trip.advance();
      place(pointAlongPath(trip.path, trip.progress));
      if (trip.progress >= 1) {
        _active.remove(driverId);
        _rides.completeRide(ride.id);
        _rides.notify(
          kind: NotificationKind.ride,
          title: 'Trip completed',
          body: 'You arrived at ${ride.dropoff.name}. Rate your driver.',
          rideId: ride.id,
        );
      }
    }
  }

  /* ---------------------------------------------------------------- */
  /* Bot passengers — orders for the local driver's feed              */
  /* ---------------------------------------------------------------- */

  Place _nearestPlace(LatLng coord) {
    var best = places.first;
    var bestKm = double.infinity;
    for (final p in places) {
      final km = haversineKm(p.coord, coord);
      if (km < bestKm) {
        bestKm = km;
        best = p;
      }
    }
    return best;
  }

  void _maybeSpawnBotOrder(LatLng center) {
    final me = _session.user;
    if (me == null) return;
    final open = _rides
        .openOrders(me.id)
        .where((r) => r.passengerId.startsWith('bp'))
        .length;
    if (open >= 6) return;

    final last = _timers['spawn'];
    final gapMs = open == 0 ? 3000 : _between(9000, 20000);
    if (last != null &&
        DateTime.now().difference(last).inMilliseconds < gapMs) {
      return;
    }
    _timers['spawn'] = DateTime.now();

    final pickupAt = randomPointNear(center, 4, _rng);
    final anchor = _nearestPlace(pickupAt);
    final pickupPlace = anchor.copyWith(
      id: uid('pin'),
      coord: pickupAt,
      category: PlaceCategory.area,
      address: 'Near ${anchor.name}',
    );
    // Pick a destination that is actually somewhere else — comparing ids
    // would never match, since the pickup pin carries a freshly minted one.
    final options = places
        .where((p) => p.id != anchor.id && haversineKm(p.coord, pickupAt) > 2.5)
        .toList();
    final dropoffPlace = _pick(options.isEmpty ? places : options);

    final distanceKm = roadDistanceKm(pickupPlace.coord, dropoffPlace.coord);
    final durationMinutes = driveMinutes(distanceKm);
    final vehicleClass = _rng.nextDouble() < 0.72
        ? VehicleClass.economy
        : (_rng.nextDouble() < 0.7 ? VehicleClass.comfort : VehicleClass.xl);
    final recommended = recommendedPrice(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      vehicleClass: vehicleClass,
      service: ServiceType.city,
    );
    final name = _pick(passengerNames);

    _rides.publishRide(
      Ride(
        id: uid('ride'),
        passengerId: uid('bp'),
        passengerName: name,
        passengerAvatarColor: pickAvatarColor(name),
        passengerRating: double.parse(_between(4.2, 5).toStringAsFixed(1)),
        service: ServiceType.city,
        vehicleClass: vehicleClass,
        pickup: pickupPlace,
        dropoff: dropoffPlace,
        // Bot passengers ask between a lowball and a generous offer.
        askingPrice: roundFare(recommended * _between(0.78, 1.15)),
        recommendedPrice: recommended,
        distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
        durationMinutes: durationMinutes,
        paymentMethod: _rng.nextDouble() < 0.6
            ? PaymentMethod.cash
            : PaymentMethod.card,
        passengerCount: _rng.nextDouble() < 0.8 ? 1 : 2 + _rng.nextInt(3),
        comment: _rng.nextDouble() < 0.3 ? _pick(pickupNotes) : null,
        options: _rng.nextDouble() < 0.2 ? [RideOption.luggage] : const [],
        status: RideStatus.searching,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        priceRaises: 0,
        routeGeometry: syntheticRoute(pickupPlace.coord, dropoffPlace.coord, 3),
      ),
    );
  }

  /// Bot passengers weigh the local driver's bid and answer after a beat.
  void _resolveBotDecisions() {
    final me = _session.user;
    if (me == null) return;
    final mine = _rides.offers.values
        .where((o) => o.status == OfferStatus.pending && o.driverId == me.id)
        .toList();

    for (final offer in mine) {
      final ride = _rides.rides[offer.rideId];
      if (ride == null ||
          !ride.passengerId.startsWith('bp') ||
          ride.status != RideStatus.searching) {
        continue;
      }
      final key = 'decide:${offer.id}';
      final first = _timers[key];
      if (first == null) {
        _timers[key] = DateTime.now();
        continue;
      }
      // Bot passengers think for 4-10 seconds before answering.
      final delayMs =
          4000 + (offer.price / math.max(1, ride.askingPrice)) * 4000;
      if (DateTime.now().difference(first).inMilliseconds < delayMs) continue;
      _timers.remove(key);

      final overAsk = offer.price / ride.askingPrice;
      final acceptChance = overAsk <= 1.0
          ? 0.92
          : overAsk <= 1.12
          ? 0.62
          : overAsk <= 1.3
          ? 0.3
          : 0.08;
      if (_rng.nextDouble() < acceptChance) {
        _rides.acceptOffer(offer.id);
        _rides.notify(
          kind: NotificationKind.ride,
          title: 'Your offer was accepted',
          body: '${ride.passengerName} accepted. Head to ${ride.pickup.name}.',
          rideId: ride.id,
        );
      } else {
        _rides.declineOffer(offer.id);
        _rides.notify(
          kind: NotificationKind.ride,
          title: 'Offer declined',
          body: '${ride.passengerName} chose another driver.',
          rideId: ride.id,
        );
      }
    }
  }

  /// Bot passengers give up on orders nobody wants, and sometimes raise first.
  void _ageBotOrders() {
    for (final ride in _rides.rides.values.toList()) {
      if (ride.status != RideStatus.searching) continue;
      if (!ride.passengerId.startsWith('bp')) continue;
      final ageMs = DateTime.now().difference(ride.createdAt).inMilliseconds;
      if (ageMs > 45000 && ride.priceRaises < 2 && _rng.nextDouble() < 0.02) {
        _rides.updateRide(
          ride.id,
          (r) => r.copyWith(
            askingPrice: roundFare(r.askingPrice * 1.12),
            priceRaises: r.priceRaises + 1,
          ),
        );
      }
      if (ageMs > 150000) {
        _rides.cancelRide(ride.id, CancelledBy.passenger, 'No longer needed');
      }
    }
  }

  /* ---------------------------------------------------------------- */
  /* Tick                                                             */
  /* ---------------------------------------------------------------- */

  void _onTick() {
    final me = _session.user;
    if (me == null || !_session.prefs.simulationEnabled) return;
    final center = _session.myLocation;

    _ensureFleet(center);

    final all = _rides.rides.values.toList();

    // Bot drivers currently on a job.
    final botJobs = all.where((r) {
      final id = r.driverId;
      return id != null &&
          id.startsWith('bot') &&
          const {
            RideStatus.accepted,
            RideStatus.arriving,
            RideStatus.waiting,
            RideStatus.inProgress,
          }.contains(r.status);
    }).toList();
    for (final ride in botJobs) {
      _driveBot(ride);
    }
    final busy = botJobs.map((r) => r.driverId!).toSet();

    // Idle bots cruise around.
    for (final driver in _fleet) {
      if (busy.contains(driver.id)) continue;
      _wanderBot(driver, center);
    }

    // Bots bid on the local passenger's live order.
    for (final ride in all) {
      if (ride.status == RideStatus.searching && ride.passengerId == me.id) {
        _botsBidOn(ride);
      }
    }

    // Driver-side marketplace.
    if (_session.prefs.role == Role.driver && _session.prefs.driverOnline) {
      _maybeSpawnBotOrder(center);
    }
    _resolveBotDecisions();
    _ageBotOrders();
  }
}

class _BotTrip {
  _BotTrip(this.path, this.speed);

  final List<LatLng> path;

  /// Fraction of the path covered per tick.
  final double speed;
  double progress = 0;

  void advance() => progress = math.min(1, progress + speed);
}
