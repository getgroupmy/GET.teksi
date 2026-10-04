import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/duty.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/services/duty_presence.dart';
import 'package:get_teksi/state/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The foreground service is a promise with two ways to break it. Failing to
/// start one means a driver who looks online to the server and is frozen in
/// fact — no position, no offers, no bell. Failing to stop one means a
/// notification they cannot dismiss and a battery drain they did not agree to,
/// long after they went off duty.
///
/// Everything here drives the rule, not the platform: what gets asked for, and
/// how often.

const _car = Vehicle(
  make: 'Perodua',
  model: 'Myvi',
  year: 2022,
  color: 'White',
  plate: 'WXY 1234',
  vehicleClass: VehicleClass.economy,
  seats: 4,
);

/// Records what was asked of the platform, and can refuse.
class _RecordingDuty implements DutyService {
  final List<String> calls = [];
  bool grant = true;

  @override
  Future<bool> start({required String title, required String body}) async {
    calls.add('start:$title');
    return grant;
  }

  @override
  Future<void> stop() async => calls.add('stop');
}

void main() {
  late SessionStore session;
  late _RecordingDuty service;

  const title = 'You are online';
  const body = 'Waiting for orders.';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    service = _RecordingDuty();
  });

  DutyPresence presenceWith({bool backendLive = true}) =>
      DutyPresence(session, service: service, backendLive: backendLive);

  /// Signs in a driver and puts them on duty.
  void goOnDuty() {
    session.signIn('+60123456789', name: 'Ravi', id: 'driver-1');
    session.becomeDriver(_car);
    session.setRole(Role.driver);
    session.setPrefs(session.prefs.copyWith(driverOnline: true));
  }

  test('a driver going on duty asks the platform to stay awake', () async {
    goOnDuty();
    await presenceWith().sync(title: title, body: body);

    expect(service.calls, ['start:$title']);
  });

  test('a passenger never asks for it', () async {
    // The service is a driver's tool. A passenger's app has nothing to publish
    // while it is in the background, and an ongoing notification would be
    // battery spent on nothing.
    session.signIn('+60111111111', name: 'Aisyah', id: 'passenger-1');
    await presenceWith().sync(title: title, body: body);

    expect(service.calls, isEmpty);
  });

  test('a driver who is off duty does not', () async {
    goOnDuty();
    session.setPrefs(session.prefs.copyWith(driverOnline: false));
    await presenceWith().sync(title: title, body: body);

    expect(service.calls, isEmpty);
  });

  test('a driver looking at the passenger half does not either', () async {
    // Same account, same duty switch, but they are riding rather than driving.
    // The beacon reads the same three conditions, and the two must agree.
    goOnDuty();
    session.setRole(Role.passenger);
    await presenceWith().sync(title: title, body: body);

    expect(service.calls, isEmpty);
  });

  test('there is nothing to stay awake for without a backend', () async {
    // The other participants are bots in this same process. They need nobody
    // awake, and a driver would pay for it in battery.
    goOnDuty();
    await presenceWith(backendLive: false).sync(title: title, body: body);

    expect(service.calls, isEmpty);
  });

  test('going off duty stops it', () async {
    goOnDuty();
    final duty = presenceWith();
    await duty.sync(title: title, body: body);

    session.setPrefs(session.prefs.copyWith(driverOnline: false));
    await duty.sync(title: title, body: body);

    expect(service.calls, ['start:$title', 'stop']);
    expect(duty.isRunning, isFalse);
  });

  test('signing out stops it', () async {
    // signOut() clears the role and the duty switch, which is what makes this
    // work — but the point is that no separate teardown is needed for it to.
    goOnDuty();
    final duty = presenceWith();
    await duty.sync(title: title, body: body);

    session.signOut();
    await duty.sync(title: title, body: body);

    expect(service.calls.last, 'stop');
  });

  test('a rebuild that changed nothing costs nothing', () async {
    // This is driven from a post-frame callback, so it runs on every build.
    // A channel call per frame would be a real cost for a service that is
    // already exactly as the app wants it.
    goOnDuty();
    final duty = presenceWith();
    for (var i = 0; i < 20; i++) {
      await duty.sync(title: title, body: body);
    }

    expect(service.calls, hasLength(1));
  });

  test('switching language restarts it with the new words', () async {
    // The one notification a driver looks at all evening. Leaving it in the
    // language they just switched away from is the kind of thing nobody
    // notices until a driver does.
    goOnDuty();
    final duty = presenceWith();
    await duty.sync(title: title, body: body);

    await duty.sync(title: 'Anda dalam talian', body: 'Menunggu pesanan.');

    expect(service.calls, ['start:$title', 'start:Anda dalam talian']);
  });

  test('a refused start is not retried on every frame', () async {
    // Android can refuse: the location permission is gone, or an OEM battery
    // manager has opinions. The app then works as it did before any of this
    // existed, which is a worse guarantee and not a broken app — and it must
    // not turn into a channel call per frame asking again.
    goOnDuty();
    service.grant = false;
    final duty = presenceWith();
    await duty.sync(title: title, body: body);
    await duty.sync(title: title, body: body);
    await duty.sync(title: title, body: body);

    expect(service.calls, hasLength(1));
    expect(duty.isRunning, isFalse);
  });

  test('a refused start is retried once something changes', () async {
    goOnDuty();
    service.grant = false;
    final duty = presenceWith();
    await duty.sync(title: title, body: body);

    // Off duty and on again: the driver has done something, which is the point
    // at which asking again is worth it rather than noise.
    session.setPrefs(session.prefs.copyWith(driverOnline: false));
    await duty.sync(title: title, body: body);
    service.grant = true;
    session.setPrefs(session.prefs.copyWith(driverOnline: true));
    await duty.sync(title: title, body: body);

    expect(service.calls, ['start:$title', 'stop', 'start:$title']);
    expect(duty.isRunning, isTrue);
  });

  test('disposing ends the service', () async {
    goOnDuty();
    final duty = presenceWith();
    await duty.sync(title: title, body: body);

    await duty.dispose();

    expect(service.calls.last, 'stop');
    expect(duty.isRunning, isFalse);
  });

  test('the do-nothing service says so rather than pretending', () async {
    // What every platform but Android gets. A caller that believed a false
    // promise would be a driver told the app will keep working when it will
    // not.
    const quiet = NoDutyService();

    expect(await quiet.start(title: title, body: body), isFalse);
    await quiet.stop();
  });
}
