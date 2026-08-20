import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/location.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/data/places.dart';
import 'package:get_teksi/state/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The native halves of this cannot be exercised here — CI compiles the Kotlin
/// and the Swift, and neither runs without a device. What can be pinned is the
/// contract between them and the app, which is where a location feature
/// usually goes wrong: not in failing to get a fix, but in what it does to the
/// app when it cannot.
///
/// Every one of these is a way the platform declines to answer. The app has to
/// keep working through all of them, because a rider who says no to the
/// permission prompt is not a rider who should be shown a broken map.

const _channel = MethodChannel('get.teksi/location');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Stands in for the native side. A null handler is what a platform with no
  /// implementation looks like, and raises MissingPluginException.
  void answerWith(Future<Object?> Function(MethodCall)? handler) {
    messenger.setMockMethodCallHandler(_channel, handler);
  }

  setUp(() async {
    // SessionStore reads persisted state on construction.
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  tearDown(() => answerWith(null));

  group('a fix that arrives', () {
    test('is read from the channel', () async {
      answerWith((_) async => <String, double>{'lat': 3.0738, 'lng': 101.5183});

      final fix = await const DeviceLocationService().current();
      expect(fix, isNotNull);
      expect(fix!.latitude, closeTo(3.0738, 1e-9));
      expect(fix.longitude, closeTo(101.5183, 1e-9));
    });

    test('moves the session off the seeded city centre', () async {
      answerWith((_) async => <String, double>{'lat': 3.0738, 'lng': 101.5183});

      final session = SessionStore(location: const DeviceLocationService());
      expect(session.myLocation, cityCenter, reason: 'starts seeded');

      await session.locate();
      expect(session.myLocation.latitude, closeTo(3.0738, 1e-9));
    });
  });

  group('a fix that does not', () {
    test('null — permission refused, or location switched off', () async {
      answerWith((_) async => null);
      expect(await const DeviceLocationService().current(), isNull);
    });

    test('no implementation on this platform', () async {
      // What web got before it had its own implementation, and what any future
      // target gets on day one.
      answerWith(null);
      expect(await const DeviceLocationService().current(), isNull);
    });

    test('the native side throwing', () async {
      answerWith((_) async => throw PlatformException(code: 'FAILED'));
      expect(await const DeviceLocationService().current(), isNull);
    });

    test('a half-built payload', () async {
      // A latitude with no longitude is not a location. Reading it as one
      // would put the rider on the equator.
      answerWith((_) async => <String, double>{'lat': 3.0738});
      expect(await const DeviceLocationService().current(), isNull);
    });

    test('silence — the timeout bounds the wait', () async {
      // A phone indoors can be waiting for a first fix forever. The app opens
      // on the city centre instead of on a spinner.
      answerWith((_) => Completer<Object?>().future);

      final service = const DeviceLocationService(
        timeout: Duration(milliseconds: 50),
      );
      expect(await service.current(), isNull);
    });
  });

  test('the session keeps its last known position when a fix fails', () async {
    // The important consequence: a failed locate() must not blank out a
    // position the app already had, or a rider mid-trip loses the map.
    answerWith((_) async => <String, double>{'lat': 3.0738, 'lng': 101.5183});
    final session = SessionStore(location: const DeviceLocationService());
    await session.locate();

    answerWith((_) async => null);
    await session.locate();

    expect(session.myLocation.latitude, closeTo(3.0738, 1e-9));
  });

  test('the seeded service is unchanged, so the suite stays offline', () async {
    expect(await const SeededLocationService().current(), cityCenter);
  });
}
