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
      expect(judgePrice(600, 1000).tone, PriceTone.low);
    });

    test('treats the anchor itself as fair', () {
      expect(judgePrice(1000, 1000).tone, PriceTone.fair);
    });

    test('calls a modest premium a great price', () {
      expect(judgePrice(1200, 1000).tone, PriceTone.good);
    });

    test('flags a large premium as above market', () {
      expect(judgePrice(1800, 1000).tone, PriceTone.high);
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
