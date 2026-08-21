import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// Events that move ride state between participants.
sealed class BusEvent {
  const BusEvent();
}

class RidePublished extends BusEvent {
  const RidePublished(this.ride);
  final Ride ride;
}

class RideUpdated extends BusEvent {
  const RideUpdated(this.ride);
  final Ride ride;
}

class RideCancelled extends BusEvent {
  const RideCancelled(this.rideId, this.by, this.reason);
  final String rideId;
  final CancelledBy by;
  final String? reason;
}

class OfferCreated extends BusEvent {
  const OfferCreated(this.offer);
  final Offer offer;
}

class OfferUpdated extends BusEvent {
  const OfferUpdated(this.offer);
  final Offer offer;
}

class ChatSent extends BusEvent {
  const ChatSent(this.message);
  final ChatMessage message;
}

class DriverMoved extends BusEvent {
  const DriverMoved(this.driverId, this.coord, this.bearing);
  final String driverId;
  final LatLng coord;
  final double bearing;
}

/// A driver stopped working, so their car leaves everyone else's map.
///
/// Distinct from [DriverMoved] rather than a flag on it, because going off duty
/// is not a kind of movement. Folding the two together is how a car ends up
/// parked on a passenger's map forever: the offline write is still a row
/// change, and a listener that only knows how to move things moves it.
class DriverWentOffline extends BusEvent {
  const DriverWentOffline(this.driverId);
  final String driverId;
}

/// How ride state reaches other participants.
///
/// The app ships with [LocalTransport], which keeps everything on-device: the
/// simulated marketplace and a single real user share one process, so a plain
/// broadcast stream is all the fan-out needed.
///
/// This is the single seam for going multi-device. A production transport
/// implements the same two members against websockets, Supabase Realtime,
/// MQTT or similar — publishing [BusEvent]s to the server and surfacing
/// remote ones on [events]. Nothing above this file changes.
abstract class RealtimeTransport {
  Stream<BusEvent> get events;

  /// Publishes to every other participant. The caller has already applied the
  /// change locally, so implementations must not echo it back.
  void publish(BusEvent event);

  void dispose();
}

class LocalTransport implements RealtimeTransport {
  final _controller = StreamController<BusEvent>.broadcast();

  @override
  Stream<BusEvent> get events => _controller.stream;

  @override
  void publish(BusEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  @override
  void dispose() => _controller.close();
}

RealtimeTransport _bus = LocalTransport();

/// Process-wide transport instance.
///
/// Defaults to [LocalTransport] so the app is fully usable with nothing
/// configured; `main()` swaps in a backend-backed transport when one is
/// available. This stays a plain global rather than a provider because the
/// stores subscribe once at construction and never rebuild against it.
RealtimeTransport get bus => _bus;

/// Replaces the transport, disposing the one being retired.
///
/// Must run before any store subscribes — a store holds the stream it was
/// given, so swapping underneath a live subscription would leave it listening
/// to a transport nothing publishes to.
void setTransport(RealtimeTransport transport) {
  if (identical(transport, _bus)) return;
  _bus.dispose();
  _bus = transport;
}
