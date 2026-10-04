import 'dart:math' as math;

import '../core/formats.dart';
import '../models/models.dart';

/// Fare recommendation. Unlike a metered service the number here is only an
/// anchor — the passenger may offer above or below it, and drivers may
/// counter. We surface how far an offer sits from the anchor so both sides
/// can judge whether a bid is realistic.

class _Tariff {
  const _Tariff(this.base, this.perKm, this.perMin, this.minimum);
  final int base;
  final int perKm;
  final int perMin;
  final int minimum;
}

/// Sen. Loosely calibrated to Klang Valley street pricing.
const _tariffs = <VehicleClass, _Tariff>{
  VehicleClass.economy: _Tariff(300, 110, 18, 500),
  VehicleClass.comfort: _Tariff(450, 155, 25, 800),
  VehicleClass.xl: _Tariff(600, 200, 32, 1100),
};

const _serviceMultiplier = <ServiceType, double>{
  ServiceType.city: 1,
  // Cheaper per km — long highway legs, less stop-start.
  ServiceType.intercity: 0.85,
  ServiceType.delivery: 0.75,
  ServiceType.freight: 1.6,
  ServiceType.moto: 0.5,
};

/// Peak-hour pressure. Not a surge charge — it only moves the anchor.
double demandFactor([DateTime? at]) {
  final now = at ?? DateTime.now();
  final hour = now.hour;
  final weekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  if (!weekend && ((hour >= 7 && hour < 10) || (hour >= 17 && hour < 20))) {
    return 1.22;
  }
  if (hour >= 23 || hour < 5) return 1.15;
  if (weekend && hour >= 18 && hour < 23) return 1.12;
  return 1;
}

int recommendedPrice({
  required double distanceKm,
  required int durationMinutes,
  required VehicleClass vehicleClass,
  required ServiceType service,
  DateTime? at,
}) {
  final tariff = _tariffs[vehicleClass]!;
  final raw =
      tariff.base + tariff.perKm * distanceKm + tariff.perMin * durationMinutes;
  final adjusted = raw * _serviceMultiplier[service]! * demandFactor(at);
  return roundFare(math.max(tariff.minimum.toDouble(), adjusted));
}

class PriceBounds {
  const PriceBounds(this.min, this.max, this.step);
  final int min;
  final int max;
  final int step;
}

/// The range a passenger can pick from, centred on the recommendation.
PriceBounds priceBounds(int recommended) =>
    PriceBounds(roundFare(recommended * 0.6), roundFare(recommended * 2.2), 50);

enum PriceTone { low, fair, good, high }

// The label and hint that go with each tone used to live on a PriceVerdict
// record built here. They are copy, so they live in lib/l10n/labels.dart now;
// this file decides what the price *is*, not what to call it.

/// How the passenger's offer reads against the recommendation. Feedback shown
/// live as they drag the fare slider.
PriceTone judgePrice(int price, int recommended) {
  final ratio = price / recommended - 1;
  if (ratio < -0.18) return PriceTone.low;
  if (ratio < 0.06) return PriceTone.fair;
  if (ratio < 0.3) return PriceTone.good;
  return PriceTone.high;
}

/// Suggested bumps shown when nobody has bid yet.
List<int> raiseSuggestions(int current) {
  final raw = [
    roundFare(current * 1.1),
    roundFare(current * 1.2),
    roundFare(current * 1.35),
  ];
  final seen = <int>{};
  return raw.where((v) => v > current && seen.add(v)).toList();
}

/// The platform's cut — deliberately low, taken from the driver rather than
/// as a spread on the fare.
const commissionRate = 0.099;

int driverNet(int fare) => (fare * (1 - commissionRate)).round();

int commissionOn(int fare) => fare - driverNet(fare);
