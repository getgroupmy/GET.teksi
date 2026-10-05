import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/state/draft.dart';
import 'package:get_teksi/screens/driver/driver_home_screen.dart';
import 'package:get_teksi/screens/passenger/passenger_home_screen.dart';
import 'package:get_teksi/widgets/driver/active_ride_sheet.dart';
import 'package:get_teksi/widgets/passenger/offers_sheet.dart';
import 'package:get_teksi/widgets/passenger/price_sheet.dart';
import 'package:get_teksi/widgets/passenger/tracking_sheet.dart';

import 'support/screens.dart';
import 'support/semantics.dart';

/// The four sheets that only exist part-way through a ride.
///
/// Both home screens choose their sheet from the user's live ride, and a
/// fixture that publishes somebody else's ride has none — so every gate that
/// walks the twenty-three screens draws the idle sheet and the order feed,
/// and the other four have never been laid out at all:
///
///   PriceSheet        a draft with both ends, before publishing
///   OffersSheet       published, drivers bidding
///   TrackingSheet     accepted, from the passenger's side
///   ActiveRideSheet   accepted, from the driver's side
///
/// The one of the four that something eventually walked into is the price
/// sheet, reached by ride_flow_test.dart taking the journey rather than
/// building a screen — and it had a `spaceBetween` Row with neither child
/// flexible, holding the trip distance beside "Everyday cars, 4 seats". This
/// covers all four on purpose instead.
///
/// These sheets hold the densest text in the app: a bid list with prices and
/// ETAs, a driver card with a vehicle and a rating, a fare that changes, and
/// countdowns. The fixture gives them long names and three bids rather than
/// one, because a card that fits a short name proves nothing and a list with
/// one row leaves the branch that marks a counter-offer unlaid-out.
void main() {
  final app = ScreenFixture();

  setUp(() async => app.reset());

  /// Lays the screen out and returns the first overflow complaint, or null.
  Future<String?> layout(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    required Locale locale,
  }) async {
    final complaints = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final creator = details.informationCollector
          ?.call()
          .map((node) => node.toString())
          .firstWhere(
            (line) => line.startsWith('debugCreator:'),
            orElse: () => '',
          );
      complaints.add(
        creator == null || creator.isEmpty
            ? '${details.exception}'
            : '${details.exception}\n    in '
                  '${creator.substring('debugCreator: '.length)}',
      );
    };
    addTearDown(() => FlutterError.onError = previous);

    app.sizeAsPhone(tester);
    await tester.pumpWidget(app.wrap(screen, scale: scale, locale: locale));
    await tester.pump(const Duration(milliseconds: 350));
    // Restored before the caller's expects, or the binding asserts about an
    // override left in place while expect() runs.
    FlutterError.onError = previous;
    return complaints.isEmpty ? null : complaints.first;
  }

  /// One sheet, the state that produces it, and the type that proves it is
  /// the one on screen. Without the proof a state that stopped producing its
  /// sheet would leave this measuring the idle sheet and reporting it clean.
  final states =
      <String, ({void Function() setUp, Widget Function() screen, Type sheet})>{
        'PriceSheet': (
          setUp: () {
            app.draft.setPickup(place('KLCC Tower 2 North Entrance', klcc));
            app.draft.setDropoff(
              place('Mid Valley Megamall South Court', midValley),
            );
            app.draft.setStep(DraftStep.price);
          },
          screen: () => const PassengerHomeScreen(),
          sheet: PriceSheet,
        ),
        'OffersSheet': (
          setUp: () => app.giveLiveRide(
            as: Role.passenger,
            status: RideStatus.searching,
            withOffers: true,
          ),
          screen: () => const PassengerHomeScreen(),
          sheet: OffersSheet,
        ),
        for (final status in [
          RideStatus.accepted,
          RideStatus.arriving,
          RideStatus.waiting,
          RideStatus.inProgress,
        ])
          'TrackingSheet, ${status.name}': (
            setUp: () => app.giveLiveRide(as: Role.passenger, status: status),
            screen: () => const PassengerHomeScreen(),
            sheet: TrackingSheet,
          ),
        for (final status in [
          RideStatus.accepted,
          RideStatus.arriving,
          RideStatus.waiting,
          RideStatus.inProgress,
        ])
          'ActiveRideSheet, ${status.name}': (
            setUp: () => app.giveLiveRide(as: Role.driver, status: status),
            screen: () => const DriverHomeScreen(),
            sheet: ActiveRideSheet,
          ),
      };

  group('the state really does produce the sheet', () {
    states.forEach((name, state) {
      testWidgets(name, (tester) async {
        state.setUp();
        await layout(
          tester,
          state.screen(),
          scale: 1.0,
          locale: const Locale('en'),
        );
        expect(
          find.byType(state.sheet),
          findsOneWidget,
          reason:
              '$name did not render, so everything measured for it below is '
              'the idle sheet again and this sheet is still unlaid-out.',
        );
      });
    });

    testWidgets('and without the state the idle sheet is what shows', (
      tester,
    ) async {
      // The other direction: if the fixture produced these sheets anyway,
      // the proofs above would pass without the setUp doing anything.
      await layout(
        tester,
        const PassengerHomeScreen(),
        scale: 1.0,
        locale: const Locale('en'),
      );
      expect(find.byType(OffersSheet), findsNothing);
      expect(find.byType(TrackingSheet), findsNothing);
      expect(find.byType(PriceSheet), findsNothing);
    });
  });

  for (final locale in appLocales) {
    final lang = locale.languageCode;
    for (final scale in [1.0, 2.0]) {
      group('in $lang at ${scale}x', () {
        states.forEach((name, state) {
          testWidgets('$name lays out', (tester) async {
            state.setUp();
            final error = await layout(
              tester,
              state.screen(),
              scale: scale,
              locale: locale,
            );
            expect(
              error,
              isNull,
              reason:
                  '$name overflows in $lang at ${scale}x. This sheet is what '
                  'the passenger or driver is looking at for the whole of a '
                  'ride:\n$error',
            );
          });
        });
      });
    }
  }

  group('every control on these sheets announces itself', () {
    states.forEach((name, state) {
      testWidgets(name, (tester) async {
        final handle = tester.ensureSemantics();
        state.setUp();
        app.sizeAsPhone(tester);
        await tester.pumpWidget(app.wrap(state.screen()));
        await tester.pump(const Duration(milliseconds: 350));

        final root = tester.getSemantics(find.byType(Scaffold).first);
        final silent = controls(root).where((n) => !announcesSomething(n));
        expect(
          silent.map(describeNode).toList(),
          isEmpty,
          reason:
              'On $name a screen reader would reach these and have nothing '
              'to read out.',
        );
        handle.dispose();
      });
    });
  });

  group('the gate itself', () {
    testWidgets('catches an overflow that is really there', (tester) async {
      // This file has its own copy of the capture, so a mistake in it would
      // pass every check above while measuring nothing. Horizontal, because
      // `wrap` gives unbounded height and a tall column simply grows.
      final error = await layout(
        tester,
        Scaffold(
          body: Row(
            children: [Container(width: 600, height: 20, color: Colors.red)],
          ),
        ),
        scale: 1.0,
        locale: const Locale('en'),
      );
      expect(error, isNotNull);
      expect(error, contains('overflowed'));
    });
  });
}
