import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/services/profile_sync.dart';
import 'package:get_teksi/state/session.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the server believes about you decides what you are allowed to do. Two
/// policies read `is_driver` straight off the profile row, so a driver whose
/// row still says false gets an empty order feed and a rejected bid — with no
/// error either time, because that is what row-level security looks like from
/// the outside.

const _car = Vehicle(
  make: 'Perodua',
  model: 'Myvi',
  year: 2022,
  color: 'White',
  plate: 'WXY 1234',
  vehicleClass: VehicleClass.economy,
  seats: 4,
);

void main() {
  late SessionStore session;
  late List<Map<String, dynamic>> pushes;
  late ProfileSync sync;

  /// Short enough to keep the tests quick, long enough to still coalesce.
  const settle = Duration(milliseconds: 20);
  const afterSettle = Duration(milliseconds: 60);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    pushes = [];
    sync = ProfileSync(
      session,
      settle: settle,
      push: (userId, columns) async => pushes.add({'id': userId, ...columns}),
    );
  });

  tearDown(() => sync.stop());

  test('nothing is sent for a signed-out device', () async {
    sync.start();
    await Future<void>.delayed(afterSettle);

    expect(pushes, isEmpty);
  });

  test(
    'the profile is sent on starting, not only on the next change',
    () async {
      // Starting usually means someone just signed in, and the server may
      // already disagree with what this device holds.
      session.signIn('+60123456789', name: 'Aisyah', id: 'user-1');
      sync.start();
      await Future<void>.delayed(afterSettle);

      expect(pushes, hasLength(1));
      expect(pushes.single['id'], 'user-1');
      expect(pushes.single['name'], 'Aisyah');
      expect(pushes.single['is_driver'], isFalse);
    },
  );

  test('becoming a driver reaches the server', () async {
    // The one that matters. Without this the order feed is empty and every bid
    // is refused, and the app has no way to know why.
    session.signIn('+60123456789', name: 'Ravi', id: 'user-1');
    sync.start();
    await Future<void>.delayed(afterSettle);

    session.becomeDriver(_car);
    await Future<void>.delayed(afterSettle);

    expect(pushes, hasLength(2));
    expect(pushes.last['is_driver'], isTrue);
    expect((pushes.last['vehicle'] as Map)['plate'], 'WXY 1234');
  });

  test('a changed vehicle reaches the server too', () async {
    session.signIn('+60123456789', name: 'Ravi', id: 'user-1');
    session.becomeDriver(_car);
    sync.start();
    await Future<void>.delayed(afterSettle);
    final before = pushes.length;

    session.updateVehicle(plate: 'WAA 9999', color: 'Blue');
    await Future<void>.delayed(afterSettle);

    expect(pushes.length, before + 1);
    expect((pushes.last['vehicle'] as Map)['plate'], 'WAA 9999');
  });

  test('a notification that changes no profile column costs nothing', () async {
    // SessionStore notifies for things that are not the profile — a new
    // position, most often. Writing on every one of those would be a stream of
    // writes of the same row.
    session.signIn('+60123456789', name: 'Aisyah', id: 'user-1');
    sync.start();
    await Future<void>.delayed(afterSettle);
    final before = pushes.length;

    session.setMyLocation(const LatLng(3.2000, 101.7000));
    await Future<void>.delayed(afterSettle);

    expect(pushes, hasLength(before));
  });

  test('a burst of changes collapses into one write', () async {
    session.signIn('+60123456789', name: 'Ravi', id: 'user-1');
    sync.start();
    await Future<void>.delayed(afterSettle);
    final before = pushes.length;

    // Onboarding sets a role and a vehicle in the same breath.
    session.becomeDriver(_car);
    session.updateVehicle(plate: 'WBB 2222', color: 'Red');
    await Future<void>.delayed(afterSettle);

    expect(pushes.length, before + 1);
    expect((pushes.last['vehicle'] as Map)['plate'], 'WBB 2222');
  });

  test('only columns a client may write are sent', () async {
    // The guard trigger refuses the wallet balance, the ratings, the trip
    // counts and the verification flag. Sending them would make every save a
    // rejected statement rather than a partial one.
    session.signIn('+60123456789', name: 'Ravi', id: 'user-1');
    session.becomeDriver(_car);
    sync.start();
    await Future<void>.delayed(afterSettle);

    expect(
      pushes.last.keys,
      unorderedEquals([
        'id',
        'name',
        'email',
        'avatar_color',
        'is_driver',
        'vehicle',
      ]),
    );
  });

  test('a failed push is retried on the next change', () async {
    // A profile a few seconds stale on the server is worth less noise than a
    // dialog about a write the user never asked for — but it must not be
    // stale for good.
    var failNext = true;
    final attempts = <Map<String, dynamic>>[];
    final flaky = ProfileSync(
      session,
      settle: settle,
      push: (userId, columns) async {
        attempts.add(columns);
        if (failNext) {
          failNext = false;
          throw StateError('network');
        }
      },
    );
    session.signIn('+60123456789', name: 'Ravi', id: 'user-1');
    flaky.start();
    await Future<void>.delayed(afterSettle);
    expect(attempts, hasLength(1));

    session.becomeDriver(_car);
    await Future<void>.delayed(afterSettle);

    expect(attempts, hasLength(2));
    expect(attempts.last['is_driver'], isTrue);
    flaky.stop();
  });

  test('stopping ends the syncing', () async {
    session.signIn('+60123456789', name: 'Ravi', id: 'user-1');
    sync.start();
    await Future<void>.delayed(afterSettle);
    final before = pushes.length;

    sync.stop();
    session.becomeDriver(_car);
    await Future<void>.delayed(afterSettle);

    expect(pushes, hasLength(before));
    expect(sync.isRunning, isFalse);
  });
}
