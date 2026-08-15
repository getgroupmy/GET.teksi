import 'package:flutter/foundation.dart';

import '../core/geo.dart';
import '../models/models.dart';
import '../services/pricing.dart';

enum DraftStep { idle, price }

enum DraftField { pickup, dropoff, stop }

class TripEstimate {
  const TripEstimate(this.distanceKm, this.durationMinutes, this.recommended);
  final double distanceKm;
  final int durationMinutes;
  final int recommended;
}

/// The passenger's in-progress order. Kept apart from [RidesStore] so an
/// abandoned composition never leaks into history.
class DraftStore extends ChangeNotifier {
  DraftStep step = DraftStep.idle;
  ServiceType service = ServiceType.city;
  VehicleClass vehicleClass = VehicleClass.economy;
  Place? pickup;
  Place? dropoff;
  Place? stop;
  int price = 0;
  PaymentMethod paymentMethod = PaymentMethod.cash;
  int passengerCount = 1;
  String comment = '';
  List<RideOption> options = [];
  String? promoCode;

  /// Which field the destination search is editing.
  DraftField editing = DraftField.dropoff;

  TripEstimate? get trip {
    final p = pickup;
    final d = dropoff;
    if (p == null || d == null) return null;
    final s = stop;
    final legs = s == null
        ? roadDistanceKm(p.coord, d.coord)
        : roadDistanceKm(p.coord, s.coord) + roadDistanceKm(s.coord, d.coord);
    final distanceKm = double.parse(legs.toStringAsFixed(2));
    // A mid-route stop costs the driver a few minutes of waiting.
    final durationMinutes = driveMinutes(distanceKm) + (s == null ? 0 : 4);
    return TripEstimate(
      distanceKm,
      durationMinutes,
      recommendedPrice(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        vehicleClass: vehicleClass,
        service: service,
      ),
    );
  }

  void _resetPriceToRecommended() {
    final t = trip;
    if (t != null) price = t.recommended;
  }

  void setStep(DraftStep next) {
    step = next;
    notifyListeners();
  }

  void setService(ServiceType next) {
    service = next;
    _resetPriceToRecommended();
    notifyListeners();
  }

  void setVehicleClass(VehicleClass next) {
    vehicleClass = next;
    if (passengerCount > (next == VehicleClass.xl ? 6 : 4)) passengerCount = 1;
    _resetPriceToRecommended();
    notifyListeners();
  }

  void setPickup(Place? next) {
    pickup = next;
    _resetPriceToRecommended();
    notifyListeners();
  }

  void setDropoff(Place? next) {
    dropoff = next;
    _resetPriceToRecommended();
    notifyListeners();
  }

  void setStop(Place? next) {
    stop = next;
    _resetPriceToRecommended();
    notifyListeners();
  }

  void setEditing(DraftField field) {
    editing = field;
    notifyListeners();
  }

  void setPrice(int next) {
    price = next;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod next) {
    paymentMethod = next;
    notifyListeners();
  }

  void setPassengerCount(int next) {
    passengerCount = next;
    notifyListeners();
  }

  void setComment(String next) {
    comment = next;
    notifyListeners();
  }

  void toggleOption(RideOption option) {
    options = options.contains(option)
        ? (options.where((o) => o != option).toList())
        : [...options, option];
    notifyListeners();
  }

  void setPromoCode(String? code) {
    promoCode = code;
    notifyListeners();
  }

  void clear() {
    step = DraftStep.idle;
    service = ServiceType.city;
    vehicleClass = VehicleClass.economy;
    pickup = null;
    dropoff = null;
    stop = null;
    price = 0;
    paymentMethod = PaymentMethod.cash;
    passengerCount = 1;
    comment = '';
    options = [];
    promoCode = null;
    editing = DraftField.dropoff;
    notifyListeners();
  }

  /// Keeps the pickup pin but drops the destination — used after a ride ends.
  void clearRoute() {
    step = DraftStep.idle;
    dropoff = null;
    stop = null;
    comment = '';
    options = [];
    notifyListeners();
  }
}
