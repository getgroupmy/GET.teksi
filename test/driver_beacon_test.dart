import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/bus.dart';
import 'package:get_teksi/core/location.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/services/driver_beacon.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'marketplace_test.dart' show buildRide;

/// The beacon is the only thing that ever tells anyone else where a real driver
/// is, so what it declines to send matters as much as what it sends. These are
/// mostly about the declining.

/// A location source a test can steer, including into failure.
class _ScriptedLocation implements LocationService {
  _ScriptedLocation(this.fixes);

  /// Consumed one per call. A null entry is a device that could not answer.
  final List<LatLng?> fixes;
  int calls = 0;

  /// Delays the answer, to model a fix that arrives slower than the interval.
  Duration delay = Duration.zero;

  @override
  Future<LatLng?> current() async {
    final fix = fixes[calls.clamp(0, fixes.length - 1)];
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return fix;
  }
}

const _origin = LatLng(3.1338, 101.6869);

/// Roughly 100 m north of [_origin] — comfortably past the movement threshold.
const _north = LatLng(3.1347, 101.6869);

/// Roughly 3 m east of [_origin]: the scale of a stationary phone's GPS wander.
const _jitter = LatLng(3.1338, 101.68693);

/// The same wander, but around [_north]. Jitter is only jitter relative to
/// where the beacon last reported from, which is the trap this pair exists to
/// avoid: comparing a wander near one place against a report from another
/// reads as a real journey between them.
const _northJitter = LatLng(3.1347, 101.68693);

void main() {
  group('the receiving half', _receivingHalf);

  late SessionStore session;
  // Nullable rather than late: this tearDown also runs for the nested group,
  // which builds its own store and never touches this one.
  RidesStore? rides;
  late List<DriverMoved> published;
  late StreamSubscription<BusEvent> sub;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    published = [];
    sub = bus.events.listen((e) {
      if (e is DriverMoved) published.add(e);
    });
  });

  tearDown(() async {
    await sub.cancel();
    rides?.dispose();
    rides = null;
  });

  /// Signs in a driver and returns a beacon over a scripted location source.
  DriverBeacon beaconWith(
    _ScriptedLocation location, {
    Duration idle = const Duration(milliseconds: 40),
    Duration active = const Duration(milliseconds: 10),
  }) {
    session = SessionStore(location: location);
    session.signIn('+60123456789', name: 'Driver', id: 'driver-1');
    final store = RidesStore(session);
    rides = store;
    return DriverBeacon(
      session,
      store,
      idleInterval: idle,
      activeInterval: active,
    );
  }

  test('reports as soon as it starts rather than after an interval', () async {
    final beacon = beaconWith(_ScriptedLocation([_origin]));
    beacon.start();
    await Future<void>.delayed(Duration.zero);

    expect(published, hasLength(1));
    expect(published.single.driverId, 'driver-1');
    expect(published.single.coord, _origin);
    beacon.stop();
  });

  test('a stationary phone publishes once and then goes quiet', () async {
    // Every fix is within a few metres of the last — the device has not moved,
    // the GPS has merely wandered. One report, then silence.
    final beacon = beaconWith(
      _ScriptedLocation([_origin, _jitter, _origin, _jitter]),
    );
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    beacon.stop();

    expect(published, hasLength(1));
  });

  test('a parked car does not spin on the map', () async {
    // The bearing between two jitter samples is arbitrary. If the beacon
    // recomputed it from them, a stationary car would rotate at random; it must
    // hold the last heading it actually travelled on.
    final location = _ScriptedLocation([_origin, _north, _northJitter, _north]);
    final beacon = beaconWith(location);
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    beacon.stop();

    expect(published.length, greaterThanOrEqualTo(2));
    // Due north, from the one move that really happened.
    expect(published[1].bearing, closeTo(0, 1));
    // Nothing after that, because nothing after that was movement.
    expect(published, hasLength(2));
  });

  test('a real move is published with the heading it travelled', () async {
    final beacon = beaconWith(_ScriptedLocation([_origin, _north]));
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    beacon.stop();

    expect(published, hasLength(2));
    expect(published.last.coord, _north);
    expect(published.last.bearing, closeTo(0, 1));
  });

  test('a device that cannot answer keeps the last known position', () async {
    // Permission refused, location off, or no fix in time. None of those should
    // erase what the passenger is already looking at.
    final location = _ScriptedLocation([_origin, null, null]);
    final beacon = beaconWith(location);
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(published, hasLength(1));
    expect(beacon.lastPublished, _origin);
    beacon.stop();
  });

  test('a slow fix does not stack up behind itself', () async {
    // The location call is bounded by its own timeout, but that timeout can be
    // longer than the interval. Overlapping reads would publish out of order.
    final location = _ScriptedLocation([_origin, _north, _north])
      ..delay = const Duration(milliseconds: 60);
    final beacon = beaconWith(location, idle: const Duration(milliseconds: 5));
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    beacon.stop();

    // Ticks fired ~20 times; only the non-overlapping reads got through.
    expect(location.calls, lessThan(5));
  });

  test('stopping ends the reporting', () async {
    final location = _ScriptedLocation([_origin, _north, _origin, _north]);
    final beacon = beaconWith(location);
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    beacon.stop();
    final sent = published.length;

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(published, hasLength(sent));
    expect(beacon.isRunning, isFalse);
  });

  test('going off duty drops a fix that was already in flight', () async {
    // The privacy-relevant one. Cancelling the timer stops the next read but
    // not the one already awaiting an answer, so without an explicit guard a
    // driver who goes offline reports their position once more afterwards —
    // which is precisely what going offline is supposed to prevent.
    final location = _ScriptedLocation([_origin])
      ..delay = const Duration(milliseconds: 40);
    final beacon = beaconWith(location, idle: const Duration(seconds: 5));
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    beacon.stop();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(published, isEmpty);
  });

  test('carrying a passenger samples faster than idling', () async {
    // Same elapsed time, same scripted fixes; the only difference is whether
    // there is a live ride, and that has to show up as more reads.
    final idleLocation = _ScriptedLocation([_origin]);
    final idleBeacon = beaconWith(
      idleLocation,
      idle: const Duration(milliseconds: 50),
      active: const Duration(milliseconds: 5),
    );
    idleBeacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    idleBeacon.stop();
    final idleCalls = idleLocation.calls;
    rides?.dispose();

    final busyLocation = _ScriptedLocation([_origin]);
    final busyBeacon = beaconWith(
      busyLocation,
      idle: const Duration(milliseconds: 50),
      active: const Duration(milliseconds: 5),
    );
    rides!.publishRide(
      buildRide(passengerId: 'p1').copyWith(driverId: 'driver-1'),
    );
    busyBeacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    busyBeacon.stop();

    expect(busyLocation.calls, greaterThan(idleCalls));
  });

  test('a signed-out device reports nothing', () async {
    final location = _ScriptedLocation([_origin]);
    session = SessionStore(location: location);
    final store = RidesStore(session);
    rides = store;
    final beacon = DriverBeacon(
      session,
      store,
      idleInterval: const Duration(milliseconds: 10),
    );
    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    beacon.stop();

    expect(published, isEmpty);
  });
}

/// The receiving half. A driver reporting from another phone is a car the
/// passenger can see the position of and nothing else — their profile is not
/// readable, by design — so there is nothing to build a NearbyDriver from.
/// Until the store kept these separately, the position arrived and was dropped:
/// the driver moved and the map stayed empty.
void _receivingHalf() {
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

  test('a driver this device has never seen appears on the map', () {
    expect(rides.carsOnMap, isEmpty);

    rides.setDriverLocation('stranger-1', _origin, 90);

    expect(rides.carsOnMap, hasLength(1));
    expect(rides.carsOnMap.single.id, 'stranger-1');
    expect(rides.carsOnMap.single.coord, _origin);
    expect(rides.carsOnMap.single.bearing, 90);
  });

  test('a second report moves the same car rather than adding one', () {
    rides.setDriverLocation('stranger-1', _origin, 0);
    rides.setDriverLocation('stranger-1', _north, 180);

    expect(rides.carsOnMap, hasLength(1));
    expect(rides.carsOnMap.single.coord, _north);
    expect(rides.carsOnMap.single.bearing, 180);
  });

  test('going off duty takes the car off the map', () {
    rides.setDriverLocation('stranger-1', _origin, 0);
    expect(rides.carsOnMap, hasLength(1));

    rides.driverWentOffline('stranger-1');

    expect(rides.carsOnMap, isEmpty);
  });

  test('bots and reported drivers are drawn side by side', () {
    rides.upsertNearbyDriver(
      NearbyDriver(
        id: 'bot-1',
        name: 'Bot',
        avatarColor: 0,
        rating: 5,
        ridesGiven: 10,
        vehicle: const Vehicle(
          make: 'Perodua',
          model: 'Myvi',
          year: 2022,
          color: 'White',
          plate: 'WXY 1234',
          vehicleClass: VehicleClass.economy,
          seats: 4,
        ),
        coord: _origin,
        bearing: 0,
      ),
    );
    rides.setDriverLocation('stranger-1', _north, 45);

    expect(
      rides.carsOnMap.map((c) => c.id),
      containsAll(['bot-1', 'stranger-1']),
    );
  });

  test('a known driver still updates in place, not as a second car', () {
    rides.upsertNearbyDriver(
      NearbyDriver(
        id: 'bot-1',
        name: 'Bot',
        avatarColor: 0,
        rating: 5,
        ridesGiven: 10,
        vehicle: const Vehicle(
          make: 'Perodua',
          model: 'Myvi',
          year: 2022,
          color: 'White',
          plate: 'WXY 1234',
          vehicleClass: VehicleClass.economy,
          seats: 4,
        ),
        coord: _origin,
        bearing: 0,
      ),
    );
    rides.setDriverLocation('bot-1', _north, 90);

    expect(rides.carsOnMap, hasLength(1));
    expect(rides.carsOnMap.single.coord, _north);
  });
}
