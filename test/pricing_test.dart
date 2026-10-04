import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/formats.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/services/pricing.dart';

void main() {
  group('recommendedPrice', () {
    // A fixed off-peak moment keeps demandFactor out of the assertions.
    final offPeak = DateTime(2026, 1, 7, 14);

    test('rises with distance', () {
      final short = recommendedPrice(
        distanceKm: 3,
        durationMinutes: 10,
        vehicleClass: VehicleClass.economy,
        service: ServiceType.city,
        at: offPeak,
      );
      final long = recommendedPrice(
        distanceKm: 15,
        durationMinutes: 30,
        vehicleClass: VehicleClass.economy,
        service: ServiceType.city,
        at: offPeak,
      );
      expect(long, greaterThan(short));
    });

    test('respects the per-class minimum on very short trips', () {
      final fare = recommendedPrice(
        distanceKm: 0.2,
        durationMinutes: 2,
        vehicleClass: VehicleClass.xl,
        service: ServiceType.city,
        at: offPeak,
      );
      expect(fare, greaterThanOrEqualTo(1100));
    });

    test('orders the vehicle classes economy < comfort < xl', () {
      int fare(VehicleClass c) => recommendedPrice(
        distanceKm: 8,
        durationMinutes: 20,
        vehicleClass: c,
        service: ServiceType.city,
        at: offPeak,
      );
      expect(fare(VehicleClass.economy), lessThan(fare(VehicleClass.comfort)));
      expect(fare(VehicleClass.comfort), lessThan(fare(VehicleClass.xl)));
    });

    test('prices intercity below city per kilometre', () {
      int fare(ServiceType s) => recommendedPrice(
        distanceKm: 120,
        durationMinutes: 110,
        vehicleClass: VehicleClass.economy,
        service: s,
        at: offPeak,
      );
      expect(fare(ServiceType.intercity), lessThan(fare(ServiceType.city)));
    });

    test('applies peak-hour pressure to the anchor', () {
      final peak = DateTime(2026, 1, 7, 8); // Wednesday morning rush
      expect(demandFactor(peak), greaterThan(demandFactor(offPeak)));
    });
  });

  group('judgePrice', () {
    test('flags an offer well under the anchor as below market', () {
      expect(judgePrice(600, 1000), PriceTone.low);
    });

    test('treats the anchor itself as fair', () {
      expect(judgePrice(1000, 1000), PriceTone.fair);
    });

    test('calls a modest premium a great price', () {
      expect(judgePrice(1200, 1000), PriceTone.good);
    });

    test('flags a large premium as above market', () {
      expect(judgePrice(1800, 1000), PriceTone.high);
    });
  });

  group('priceBounds', () {
    test('brackets the recommendation on both sides', () {
      final b = priceBounds(2000);
      expect(b.min, lessThan(2000));
      expect(b.max, greaterThan(2000));
      expect(b.step, 50);
    });
  });

  group('raiseSuggestions', () {
    test('only ever suggests going up, with no duplicates', () {
      final suggestions = raiseSuggestions(1000);
      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s > 1000), isTrue);
      expect(suggestions.toSet().length, suggestions.length);
      expect(suggestions, orderedEquals(List.of(suggestions)..sort()));
    });
  });

  group('commission', () {
    test('driver net plus commission always reconstructs the fare', () {
      for (final fare in [500, 1234, 4700, 99999]) {
        expect(driverNet(fare) + commissionOn(fare), fare);
      }
    });

    test('keeps the driver share above 90%', () {
      expect(driverNet(10000) / 10000, greaterThan(0.9));
    });

    /// The fee has to mean the same thing in Dart and in SQL, or a driver is
    /// shown one number and paid another.
    ///
    /// This used to be a list of six worked examples, hand-copied into
    /// supabase/tests/policies.sql. Two lists is not a cross-check: each
    /// suite only ever compared its own implementation to its own literals,
    /// so changing `commissionRate` here and updating this list left the SQL
    /// side untouched, still passing, and quietly paying a different number
    /// from the one the app quotes. The guard against that was a comment
    /// asking you to remember.
    ///
    /// These read the SQL instead.
    group('agrees with the database', () {
      final ledger = File(
        'supabase/migrations/20260820140000_wallet_ledger.sql',
      ).readAsStringSync();

      /// The rate out of `private.driver_net`, as written.
      final sqlRate = RegExp(r'p_fare\s*\*\s*(\d+\.\d+)::numeric')
          .firstMatch(ledger)
          ?.group(1);

      test('the rate in the migration is the rate in pricing.dart', () {
        expect(
          sqlRate,
          isNotNull,
          reason:
              'could not find `p_fare * <rate>::numeric` in the wallet ledger '
              'migration. If driver_net was rewritten, this check has stopped '
              'checking and needs rewriting with it.',
        );
        expect(
          double.parse(sqlRate!),
          1 - commissionRate,
          reason:
              'private.driver_net() pays $sqlRate of the fare and '
              'pricing.dart quotes ${1 - commissionRate}. Whichever is wrong, '
              'a driver is shown one number and paid another.',
        );
      });

      /// Equal rates are not enough on their own. Dart multiplies in binary
      /// floating point and Postgres in exact decimal, so the two can round
      /// apart on a half-sen tie even when the rate matches. This does the
      /// SQL's arithmetic in integers — exact, half away from zero, the way
      /// `round(numeric)` does it — and holds Dart to it.
      test('rounds the same way as Postgres, fare by fare', () {
        final digits = sqlRate!.split('.')[1];
        final numerator = int.parse(sqlRate.replaceAll('.', ''));
        final scale = math.pow(10, digits.length).toInt();

        final disagreements = <String>[];
        for (var fare = 0; fare <= 200000; fare++) {
          final exact = (fare * numerator + scale ~/ 2) ~/ scale;
          if (driverNet(fare) != exact) {
            disagreements.add(
              'fare $fare: Dart ${driverNet(fare)}, SQL $exact',
            );
            if (disagreements.length == 10) break;
          }
        }
        expect(
          disagreements,
          isEmpty,
          reason:
              'driverNet() and private.driver_net() disagree on these fares. '
              'Dart multiplies in binary floating point, Postgres in exact '
              'decimal, so they can round apart on a half-sen tie:\n'
              '${disagreements.join('\n')}',
        );
      });

      /// And that the sweep above is not vacuous: the same loop, run against
      /// a rate one sen in the pound away from the real one, has to find
      /// disagreements. Otherwise a mistake in the arithmetic here reads as
      /// two implementations in perfect agreement.
      test('the sweep can tell a wrong rate from a right one', () {
        var found = 0;
        for (var fare = 1; fare <= 200000 && found == 0; fare++) {
          if (driverNet(fare) != (fare * 902 + 500) ~/ 1000) found++;
        }
        expect(
          found,
          greaterThan(0),
          reason:
              'a deliberately wrong rate produced no disagreement, so the '
              'sweep above is not comparing anything',
        );
      });
    });
  });

  group('roundFare', () {
    test('snaps to 50-sen steps', () {
      expect(roundFare(1234), 1250);
      expect(roundFare(1210), 1200);
    });

    test('never returns less than the RM1 floor', () {
      expect(roundFare(10), 100);
    });
  });

  group('money', () {
    test('formats sen as ringgit', () {
      expect(money(1234), 'RM12.34');
      expect(money(1200, decimals: false), 'RM12');
      expect(money(1234, symbol: false), '12.34');
    });
  });

  group('phoneDisplay', () {
    test('formats a Malaysian number with or without the country code', () {
      expect(phoneDisplay('60123456789'), '+60 12-345 6789');
      expect(phoneDisplay('123456789'), '+60 12-345 6789');
    });
  });
}
