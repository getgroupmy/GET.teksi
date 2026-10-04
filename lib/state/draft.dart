import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../core/routing.dart';
import '../models/models.dart';
import '../services/pricing.dart';

enum DraftStep { idle, price }

enum DraftField { pickup, dropoff, stop }

class TripEstimate {
  const TripEstimate(
    this.distanceKm,
    this.durationMinutes,
    this.recommended, {
    this.routed = false,
  });

  final double distanceKm;
  final int durationMinutes;
  final int recommended;

  /// True when these numbers came from a road network rather than the
  /// on-device estimate. The fare is anchored on the distance either way, so
  /// this is the difference between a price built on where the roads actually
  /// go and one built on a straight line with a fudge factor.
  final bool routed;
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

  /// The road route for the current waypoints, once one has arrived.
  ///
  /// Null until then, and null again the moment a waypoint changes — a route
  /// between two other places is worse than no route, because it looks like an
  /// answer.
  RoadRoute? _routed;

  /// Bumped whenever the waypoints change, so a routing reply that arrives
  /// after the passenger has moved the pin is dropped rather than applied to
  /// the wrong trip. Same shape as the beacon's guard, for the same reason:
  /// the reply outlives the question that asked it.
  int _routeGeneration = 0;

  List<LatLng> get _waypoints => [
    if (pickup != null) pickup!.coord,
    if (stop != null) stop!.coord,
    if (dropoff != null) dropoff!.coord,
  ];

  /// The geometry to draw and store on the published ride. The real route when
  /// there is one, a synthesised line when there is not.
  List<LatLng>? get routeGeometry => _routed?.geometry;

  TripEstimate? get trip {
    final p = pickup;
    final d = dropoff;
    if (p == null || d == null) return null;
    final s = stop;

    // A routed answer wins when one is in hand. It is the same two numbers,
    // measured along the roads rather than across them.
    final routed = _routed;
    if (routed != null) {
      return TripEstimate(
        routed.distanceKm,
        routed.durationMinutes,
        recommendedPrice(
          distanceKm: routed.distanceKm,
          durationMinutes: routed.durationMinutes,
          vehicleClass: vehicleClass,
          service: service,
        ),
        routed: true,
      );
    }

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

  /// Asks the route service for the real thing, and re-anchors the fare on it.
  ///
  /// The estimate is shown immediately and this refines it, rather than the
  /// screen waiting on a network call to show a price. With no routing
  /// configured the service answers null without touching the network, so this
  /// costs an await and nothing else.
  Future<void> _refineRoute() async {
    _routed = null;
    final waypoints = _waypoints;
    if (waypoints.length < 2) return;

    final generation = ++_routeGeneration;
    final route = await Routing.service.route(waypoints);
    // The passenger moved a pin while this was in flight.
    if (generation != _routeGeneration) return;
    if (route == null) return;

    // Re-anchor only if the passenger has not already named their own price.
    // Their number is the whole point of the product; a route arriving late is
    // no reason to overwrite it.
    final untouched = price == trip?.recommended;
    _routed = route;
    if (untouched) _resetPriceToRecommended();
    notifyListeners();
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
    _onWaypointsChanged();
  }

  void setDropoff(Place? next) {
    dropoff = next;
    _onWaypointsChanged();
  }

  void setStop(Place? next) {
    stop = next;
    _onWaypointsChanged();
  }

  void _onWaypointsChanged() {
    _routed = null;
    _routeGeneration++;
    _resetPriceToRecommended();
    notifyListeners();
    unawaited(_refineRoute());
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
    _routed = null;
    _routeGeneration++;
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
    _routed = null;
    _routeGeneration++;
    step = DraftStep.idle;
    dropoff = null;
    stop = null;
    comment = '';
    options = [];
    notifyListeners();
  }
}
