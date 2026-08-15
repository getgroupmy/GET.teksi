import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/bus.dart';
import '../core/geo.dart';
import '../core/storage.dart';
import '../models/models.dart';
import '../services/pricing.dart';
import 'session.dart';

/// Bids stay live for 90 seconds, then grey out.
const offerTtl = Duration(seconds: 90);

/// Orders nobody bids on expire so the driver feed never fills with ghosts.
const _rideSearchTtl = Duration(minutes: 10);

class RidesStore extends ChangeNotifier {
  RidesStore(this._session) {
    _rides = Store.instance.readJson<Map<String, Ride>>(
      _ridesKey,
      {},
      (json) => (json as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Ride.fromJson(v as Map<String, dynamic>)),
      ),
    );
    _offers = Store.instance.readJson<Map<String, Offer>>(
      _offersKey,
      {},
      (json) => (json as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Offer.fromJson(v as Map<String, dynamic>)),
      ),
    );
    _messages = Store.instance.readJson<List<ChatMessage>>(
      _chatKey,
      [],
      (json) => (json as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
    _notifications = Store.instance.readJson<List<AppNotification>>(
      _notifKey,
      [],
      (json) => (json as List<dynamic>)
          .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
    _transactions = Store.instance.readJson<List<Txn>>(
      _txKey,
      [],
      (json) => (json as List<dynamic>)
          .map((t) => Txn.fromJson(t as Map<String, dynamic>))
          .toList(),
    );

    _busSub = bus.events.listen(_applyRemote);
    _sweeper = Timer.periodic(const Duration(seconds: 3), (_) => sweep());
  }

  static const _ridesKey = 'rides';
  static const _offersKey = 'offers';
  static const _chatKey = 'chat';
  static const _notifKey = 'notifications';
  static const _txKey = 'transactions';

  final SessionStore _session;

  late Map<String, Ride> _rides;
  late Map<String, Offer> _offers;
  late List<ChatMessage> _messages;
  late List<AppNotification> _notifications;
  late List<Txn> _transactions;

  /// Live driver positions for the map. Not persisted.
  final Map<String, NearbyDriver> _nearbyDrivers = {};

  StreamSubscription<BusEvent>? _busSub;
  Timer? _sweeper;

  Map<String, Ride> get rides => _rides;
  Map<String, Offer> get offers => _offers;
  List<ChatMessage> get messages => _messages;
  List<AppNotification> get notifications => _notifications;
  List<Txn> get transactions => _transactions;
  Map<String, NearbyDriver> get nearbyDrivers => _nearbyDrivers;

  int get unreadNotifications => _notifications.where((n) => !n.read).length;

  @override
  void dispose() {
    _busSub?.cancel();
    _sweeper?.cancel();
    super.dispose();
  }

  void _persist() {
    Store.instance.writeJson(
      _ridesKey,
      _rides.map((k, v) => MapEntry(k, v.toJson())),
    );
    Store.instance.writeJson(
      _offersKey,
      _offers.map((k, v) => MapEntry(k, v.toJson())),
    );
    Store.instance.writeJson(
      _chatKey,
      _messages.length > 300
          ? _messages
                .sublist(_messages.length - 300)
                .map((m) => m.toJson())
                .toList()
          : _messages.map((m) => m.toJson()).toList(),
    );
    Store.instance.writeJson(
      _notifKey,
      _notifications.take(60).map((n) => n.toJson()).toList(),
    );
    Store.instance.writeJson(
      _txKey,
      _transactions.take(120).map((t) => t.toJson()).toList(),
    );
  }

  void _commit() {
    _persist();
    notifyListeners();
  }

  /* ---------------------------------------------------------------- */
  /* Rides                                                            */
  /* ---------------------------------------------------------------- */

  Ride publishRide(Ride ride) {
    final withRoute = ride.routeGeometry == null
        ? ride.copyWith(
            routeGeometry: syntheticRoute(
              ride.pickup.coord,
              ride.dropoff.coord,
              3,
            ),
          )
        : ride;
    _rides = {..._rides, withRoute.id: withRoute};
    _commit();
    bus.publish(RidePublished(withRoute));
    return withRoute;
  }

  Ride? updateRide(
    String id,
    Ride Function(Ride) patch, {
    bool silent = false,
  }) {
    final current = _rides[id];
    if (current == null) return null;
    final next = patch(current).copyWith(updatedAt: DateTime.now());
    _rides = {..._rides, id: next};
    _commit();
    if (!silent) bus.publish(RideUpdated(next));
    return next;
  }

  void raisePrice(String rideId, int price) {
    final ride = _rides[rideId];
    if (ride == null || ride.status != RideStatus.searching) return;
    updateRide(
      rideId,
      (r) => r.copyWith(askingPrice: price, priceRaises: r.priceRaises + 1),
    );
    notify(
      kind: NotificationKind.ride,
      title: 'Price raised',
      body: 'Nearby drivers have been notified of your new offer.',
      rideId: rideId,
    );
  }

  void cancelRide(String rideId, CancelledBy by, [String? reason]) {
    final ride = _rides[rideId];
    if (ride == null || ride.isFinished) return;
    updateRide(
      rideId,
      (r) => r.copyWith(
        status: RideStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancelledBy: by,
        cancelReason: reason,
      ),
    );
    // Every pending bid on a dead order is void.
    final next = {..._offers};
    for (final o in _offers.values) {
      if (o.rideId == rideId && o.status == OfferStatus.pending) {
        next[o.id] = o.copyWith(status: OfferStatus.declined);
      }
    }
    _offers = next;
    _commit();
    bus.publish(RideCancelled(rideId, by, reason));
    notify(
      kind: NotificationKind.ride,
      title: by == CancelledBy.driver ? 'Driver cancelled' : 'Ride cancelled',
      body: reason ?? 'The order has been cancelled.',
      rideId: rideId,
    );
  }

  void setRideStatus(String rideId, RideStatus status) {
    final now = DateTime.now();
    updateRide(rideId, (r) {
      return switch (status) {
        RideStatus.accepted => r.copyWith(status: status, acceptedAt: now),
        RideStatus.waiting => r.copyWith(status: status, arrivedAt: now),
        RideStatus.inProgress => r.copyWith(status: status, startedAt: now),
        RideStatus.completed => r.copyWith(status: status, completedAt: now),
        _ => r.copyWith(status: status),
      };
    });
  }

  void completeRide(String rideId) {
    final ride = _rides[rideId];
    if (ride == null || ride.status == RideStatus.completed) return;
    final fare = ride.fare;
    updateRide(
      rideId,
      (r) =>
          r.copyWith(status: RideStatus.completed, completedAt: DateTime.now()),
    );

    final me = _session.user;
    if (me == null) return;

    if (ride.passengerId == me.id) {
      _session.recordPassengerTrip();
      if (ride.paymentMethod == PaymentMethod.wallet) {
        _session.debitWallet(fare);
      }
      addTransaction(
        kind: TransactionKind.ridePayment,
        amount: -fare,
        description: 'Ride to ${ride.dropoff.name}',
        rideId: rideId,
      );
    }
    if (ride.driverId == me.id) {
      final net = driverNet(fare);
      _session.recordDriverEarning(net);
      addTransaction(
        kind: TransactionKind.rideEarning,
        amount: net,
        description: 'Trip from ${ride.pickup.name}',
        rideId: rideId,
      );
    }
  }

  /* ---------------------------------------------------------------- */
  /* Offers                                                           */
  /* ---------------------------------------------------------------- */

  void createOffer(Offer offer) {
    final ride = _rides[offer.rideId];
    if (ride == null || ride.status != RideStatus.searching) return;
    _offers = {..._offers, offer.id: offer};
    _commit();
    bus.publish(OfferCreated(offer));
    if (ride.passengerId == _session.user?.id) {
      notify(
        kind: NotificationKind.ride,
        title: '${offer.driverName} offered a price',
        body:
            '${offer.vehicle.make} ${offer.vehicle.model} · ${offer.etaMinutes} min away',
        rideId: ride.id,
      );
    }
  }

  void acceptOffer(String offerId) {
    final offer = _offers[offerId];
    if (offer == null || offer.status != OfferStatus.pending) return;
    final ride = _rides[offer.rideId];
    if (ride == null || ride.status != RideStatus.searching) return;

    // Accepting one bid rejects the rest — the order is off the market.
    final next = {..._offers};
    for (final o in _offers.values) {
      if (o.rideId != offer.rideId) continue;
      next[o.id] = o.copyWith(
        status: o.id == offerId ? OfferStatus.accepted : OfferStatus.declined,
      );
    }
    _offers = next;
    _commit();
    bus.publish(OfferUpdated(next[offerId]!));

    final driverStart =
        _nearbyDrivers[offer.driverId]?.coord ??
        (offer.driverId == _session.user?.id
            ? _session.myLocation
            : ride.pickup.coord);

    updateRide(
      offer.rideId,
      (r) => r.copyWith(
        status: RideStatus.accepted,
        acceptedAt: DateTime.now(),
        finalPrice: offer.price,
        driverId: offer.driverId,
        driverName: offer.driverName,
        driverAvatarColor: offer.driverAvatarColor,
        driverRating: offer.driverRating,
        driverVehicle: offer.vehicle,
        driverCoord: driverStart,
      ),
    );
  }

  void _setOfferStatus(String offerId, OfferStatus status) {
    final offer = _offers[offerId];
    if (offer == null) return;
    final next = offer.copyWith(status: status);
    _offers = {..._offers, offerId: next};
    _commit();
    bus.publish(OfferUpdated(next));
  }

  void declineOffer(String offerId) =>
      _setOfferStatus(offerId, OfferStatus.declined);

  void withdrawOffer(String offerId) =>
      _setOfferStatus(offerId, OfferStatus.withdrawn);

  /* ---------------------------------------------------------------- */
  /* Live positions                                                   */
  /* ---------------------------------------------------------------- */

  void setDriverLocation(String driverId, LatLng coord, double bearing) {
    final nearby = _nearbyDrivers[driverId];
    if (nearby != null) {
      nearby.coord = coord;
      nearby.bearing = bearing;
    }
    // Mirror onto any live ride so the passenger's map follows the car.
    var touched = false;
    final next = {..._rides};
    for (final r in _rides.values) {
      if (r.driverId != driverId || r.isFinished) continue;
      next[r.id] = r.copyWith(driverCoord: coord, driverBearing: bearing);
      touched = true;
    }
    if (touched) _rides = next;
    notifyListeners();
  }

  void upsertNearbyDriver(NearbyDriver driver) {
    _nearbyDrivers[driver.id] = driver;
    notifyListeners();
  }

  void removeNearbyDriver(String driverId) {
    _nearbyDrivers.remove(driverId);
    notifyListeners();
  }

  /* ---------------------------------------------------------------- */
  /* Chat, notifications, ledger                                      */
  /* ---------------------------------------------------------------- */

  void sendMessage(String rideId, Role from, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final message = ChatMessage(
      id: uid('msg'),
      rideId: rideId,
      from: from,
      text: trimmed,
      createdAt: DateTime.now(),
      read: false,
    );
    _messages = [..._messages, message];
    _commit();
    bus.publish(ChatSent(message));
  }

  void markChatRead(String rideId, Role viewer) {
    var changed = false;
    _messages = _messages.map((m) {
      if (m.rideId == rideId && m.from != viewer && !m.read) {
        changed = true;
        return m.copyWith(read: true);
      }
      return m;
    }).toList();
    if (changed) _commit();
  }

  void notify({
    required NotificationKind kind,
    required String title,
    required String body,
    String? rideId,
  }) {
    _notifications = [
      AppNotification(
        id: uid('ntf'),
        title: title,
        body: body,
        createdAt: DateTime.now(),
        read: false,
        kind: kind,
        rideId: rideId,
      ),
      ..._notifications,
    ].take(60).toList();
    _commit();
  }

  void markNotificationsRead() {
    if (_notifications.every((n) => n.read)) return;
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _commit();
  }

  void addTransaction({
    required TransactionKind kind,
    required int amount,
    required String description,
    String? rideId,
  }) {
    _transactions = [
      Txn(
        id: uid('tx'),
        kind: kind,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
        rideId: rideId,
      ),
      ..._transactions,
    ].take(120).toList();
    _commit();
  }

  void rateRide(String rideId, Role by, RideRating rating, {int? tip}) {
    updateRide(
      rideId,
      (r) => by == Role.passenger
          ? r.copyWith(ratingByPassenger: rating, tip: tip)
          : r.copyWith(ratingByDriver: rating),
    );
    if (by == Role.passenger && tip != null && tip > 0) {
      addTransaction(
        kind: TransactionKind.tip,
        amount: -tip,
        description: 'Tip for your driver',
        rideId: rideId,
      );
    }
  }

  /* ---------------------------------------------------------------- */
  /* Housekeeping                                                     */
  /* ---------------------------------------------------------------- */

  /// Drops expired offers and stale searching orders.
  void sweep() {
    final now = DateTime.now();
    var changed = false;

    final nextOffers = {..._offers};
    for (final o in _offers.values) {
      if (o.status == OfferStatus.pending && !o.expiresAt.isAfter(now)) {
        nextOffers[o.id] = o.copyWith(status: OfferStatus.expired);
        changed = true;
      }
    }

    final nextRides = {..._rides};
    for (final r in _rides.values) {
      if (r.status == RideStatus.searching &&
          now.difference(r.createdAt) > _rideSearchTtl) {
        nextRides[r.id] = r.copyWith(
          status: RideStatus.cancelled,
          cancelledAt: now,
          cancelledBy: CancelledBy.system,
          cancelReason: 'No drivers responded',
        );
        changed = true;
      }
    }

    if (changed) {
      _offers = nextOffers;
      _rides = nextRides;
      _commit();
    }
  }

  void reset() {
    _rides = {};
    _offers = {};
    _messages = [];
    _notifications = [];
    _transactions = [];
    _nearbyDrivers.clear();
    _commit();
  }

  /* ---------------------------------------------------------------- */
  /* Realtime: apply events published by other participants            */
  /* ---------------------------------------------------------------- */

  void _applyRemote(BusEvent event) {
    switch (event) {
      case RidePublished(:final ride):
      case RideUpdated(:final ride):
        final existing = _rides[ride.id];
        // Last-write-wins on the update stamp keeps participants convergent.
        if (existing != null && existing.updatedAt.isAfter(ride.updatedAt)) {
          return;
        }
        if (existing != null && identical(existing, ride)) return;
        _rides = {..._rides, ride.id: ride};
        _commit();
      case RideCancelled(:final rideId, :final by, :final reason):
        final ride = _rides[rideId];
        if (ride == null || ride.status == RideStatus.cancelled) return;
        _rides = {
          ..._rides,
          rideId: ride.copyWith(
            status: RideStatus.cancelled,
            cancelledAt: DateTime.now(),
            cancelledBy: by,
            cancelReason: reason,
          ),
        };
        _commit();
      case OfferCreated(:final offer):
      case OfferUpdated(:final offer):
        if (identical(_offers[offer.id], offer)) return;
        _offers = {..._offers, offer.id: offer};
        _commit();
      case ChatSent(:final message):
        if (_messages.any((m) => m.id == message.id)) return;
        _messages = [..._messages, message];
        _commit();
      case DriverMoved(:final driverId, :final coord, :final bearing):
        setDriverLocation(driverId, coord, bearing);
    }
  }

  /* ---------------------------------------------------------------- */
  /* Selectors                                                        */
  /* ---------------------------------------------------------------- */

  Ride? activeRideFor(String userId, Role role) {
    final mine = _rides.values.where(
      (r) => role == Role.passenger
          ? r.passengerId == userId
          : r.driverId == userId,
    );
    final live = mine.where((r) => r.isLive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return live.isEmpty ? null : live.first;
  }

  /// The most recent finished ride awaiting a rating from this side.
  Ride? rideAwaitingRating(String userId, Role role) {
    final done =
        _rides.values
            .where((r) => r.status == RideStatus.completed)
            .where(
              (r) => role == Role.passenger
                  ? r.passengerId == userId
                  : r.driverId == userId,
            )
            .where(
              (r) => role == Role.passenger
                  ? r.ratingByPassenger == null
                  : r.ratingByDriver == null,
            )
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.createdAt).compareTo(
              a.completedAt ?? a.createdAt,
            ),
          );
    return done.isEmpty ? null : done.first;
  }

  List<Offer> offersForRide(String rideId) {
    final list = _offers.values.where((o) => o.rideId == rideId).toList()
      ..sort((a, b) {
        final byPrice = a.price.compareTo(b.price);
        return byPrice != 0 ? byPrice : a.etaMinutes.compareTo(b.etaMinutes);
      });
    return list;
  }

  List<Offer> pendingOffersForRide(String rideId) =>
      offersForRide(rideId)
          .where((o) => o.status == OfferStatus.pending)
          .toList();

  /// Open orders a driver may bid on, newest first.
  List<Ride> openOrders(String driverId) {
    final list =
        _rides.values
            .where(
              (r) =>
                  r.status == RideStatus.searching && r.passengerId != driverId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Offer? myPendingOfferFor(String rideId, String driverId) {
    for (final o in _offers.values) {
      if (o.rideId == rideId &&
          o.driverId == driverId &&
          o.status == OfferStatus.pending) {
        return o;
      }
    }
    return null;
  }

  Set<String> pendingOfferRideIds(String driverId) => _offers.values
      .where((o) => o.driverId == driverId && o.status == OfferStatus.pending)
      .map((o) => o.rideId)
      .toSet();

  List<Ride> historyFor(String userId, Role role) {
    final list =
        _rides.values
            .where(
              (r) => role == Role.passenger
                  ? r.passengerId == userId
                  : r.driverId == userId,
            )
            .where((r) => r.isFinished)
            .toList()
          ..sort((a, b) {
            DateTime at(Ride r) =>
                r.completedAt ?? r.cancelledAt ?? r.createdAt;
            return at(b).compareTo(at(a));
          });
    return list;
  }

  List<ChatMessage> chatFor(String rideId) {
    final list = _messages.where((m) => m.rideId == rideId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  int unreadChat(String rideId, Role viewer) => _messages
      .where((m) => m.rideId == rideId && m.from != viewer && !m.read)
      .length;
}
