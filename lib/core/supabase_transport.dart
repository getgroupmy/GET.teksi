import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'bus.dart';
import 'rows.dart';

/// The multi-device transport: the same [BusEvent]s, carried by Postgres.
///
/// This is the whole of the backend integration. Nothing above [bus] knows the
/// difference between this and [LocalTransport] — the stores publish events
/// and react to events either way, which is why going from a single-device
/// demo to a real marketplace touches one file rather than every screen.
///
/// Two rules shape the implementation:
///
/// * **Publishing is fire-and-forget.** [RealtimeTransport.publish] is `void`
///   by contract, and the caller has already applied the change locally, so a
///   slow network delays other devices seeing it but never blocks this one's
///   UI. Failures surface on [errors] rather than being thrown into a
///   synchronous call that has no way to handle them.
/// * **The server is the authority on conflicts.** Accepting a bid is not an
///   update this class is permitted to make; it calls `accept_offer()`, which
///   locks the ride and decides the winner. A losing client learns it lost by
///   receiving the resulting change like any other.
class SupabaseTransport implements RealtimeTransport {
  SupabaseTransport(this._client) {
    _subscribe();
    unawaited(_loadOnlineDrivers());
  }

  final SupabaseClient _client;
  final _controller = StreamController<BusEvent>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  final _channels = <RealtimeChannel>[];

  /// Ids this device has just written. Postgres streams a change back to its
  /// own author, and re-applying our own write would be a wasted rebuild at
  /// best. The stores already resolve conflicts by `updatedAt`, so this is an
  /// optimisation rather than a correctness requirement — which is why it is
  /// safe for entries to fall out of the set.
  final _selfWrites = <String>{};

  @override
  Stream<BusEvent> get events => _controller.stream;

  /// Backend failures — a rejected write, a dropped subscription. Surfaced so
  /// the UI can tell the user their ride did not reach the marketplace,
  /// instead of leaving them staring at a request nobody received.
  Stream<Object> get errors => _errors.stream;

  /// Reports a failure that happened outside this class — a read issued
  /// directly against the client — onto the same stream, so a listener has one
  /// place to watch rather than several.
  void report(Object error) {
    if (!_errors.isClosed) _errors.add(error);
  }

  String? get _uid => _client.auth.currentUser?.id;

  void _subscribe() {
    _channels.add(
      _client
          .channel('public:rides')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'rides',
            callback: _onRideChange,
          )
          .subscribe(_onStatus),
    );

    _channels.add(
      _client
          .channel('public:offers')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'offers',
            callback: _onOfferChange,
          )
          .subscribe(_onStatus),
    );

    _channels.add(
      _client
          .channel('public:chat_messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            callback: _onChatInsert,
          )
          .subscribe(_onStatus),
    );

    _channels.add(
      _client
          .channel('public:driver_locations')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'driver_locations',
            callback: _onDriverLocation,
          )
          .subscribe(_onStatus),
    );
  }

  void _onStatus(RealtimeSubscribeStatus status, Object? error) {
    if (error != null) _errors.add(error);
  }

  /// The cars that were already on the road when this device opened the app.
  ///
  /// Realtime delivers *changes*, so a driver parked at a rank and reporting
  /// nothing new is invisible to a passenger who arrives after them — the map
  /// fills in only as drivers happen to move. This reads the current state
  /// once so it starts full and realtime keeps it that way.
  Future<void> _loadOnlineDrivers() async {
    try {
      final rows = await _client
          .from('driver_locations')
          .select('driver_id, lat, lng, bearing')
          .eq('online', true);
      final uid = _uid;
      for (final row in rows) {
        final id = row['driver_id'] as String;
        if (id == uid) continue;
        _emit(
          DriverMoved(
            id,
            LatLng(
              (row['lat'] as num).toDouble(),
              (row['lng'] as num).toDouble(),
            ),
            (row['bearing'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    } catch (e) {
      // A map that fills in as drivers move is worse than one that starts
      // full, and much better than a screen that failed to open.
      _errors.add(e);
    }
  }

  // -------------------------------------------------------------------------
  // Inbound
  // -------------------------------------------------------------------------

  void _emit(BusEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void _onRideChange(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return;
    try {
      final ride = rideFromRow(row);
      if (_consumeSelfWrite(ride.id)) return;

      // A ride reaching a terminal cancelled state is its own event, because
      // the receiving side shows a dialog rather than a silent state change.
      if (ride.status == RideStatus.cancelled) {
        _emit(
          RideCancelled(
            ride.id,
            ride.cancelledBy ?? CancelledBy.system,
            ride.cancelReason,
          ),
        );
        return;
      }

      _emit(
        payload.eventType == PostgresChangeEvent.insert
            ? RidePublished(ride)
            : RideUpdated(ride),
      );
    } catch (e) {
      _errors.add(e);
    }
  }

  void _onOfferChange(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return;
    try {
      final offer = offerFromRow(row);
      if (_consumeSelfWrite(offer.id)) return;
      _emit(
        payload.eventType == PostgresChangeEvent.insert
            ? OfferCreated(offer)
            : OfferUpdated(offer),
      );
    } catch (e) {
      _errors.add(e);
    }
  }

  void _onChatInsert(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return;
    try {
      final message = chatFromRow(row);
      if (_consumeSelfWrite(message.id)) return;
      _emit(ChatSent(message));
    } catch (e) {
      _errors.add(e);
    }
  }

  void _onDriverLocation(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return;
    try {
      final id = row['driver_id'] as String;
      if (id == _uid) return;
      // Going off duty is an update to this row like any other, so without this
      // the car is "moved" to wherever it last was and parks there forever.
      if (row['online'] == false) {
        _emit(DriverWentOffline(id));
        return;
      }
      _emit(
        DriverMoved(
          id,
          LatLng(
            (row['lat'] as num).toDouble(),
            (row['lng'] as num).toDouble(),
          ),
          (row['bearing'] as num?)?.toDouble() ?? 0,
        ),
      );
    } catch (e) {
      _errors.add(e);
    }
  }

  bool _consumeSelfWrite(String id) => _selfWrites.remove(id);

  // -------------------------------------------------------------------------
  // Outbound
  // -------------------------------------------------------------------------

  @override
  void publish(BusEvent event) {
    final uid = _uid;
    // Signed out, or an event authored by a simulated bot rather than by this
    // account. Either way the write would be rejected by row-level security,
    // so it is dropped here rather than turned into a round trip and an error.
    if (uid == null) return;
    unawaited(_publish(event, uid).catchError(_errors.add));
  }

  Future<void> _publish(BusEvent event, String uid) async {
    switch (event) {
      case RidePublished(:final ride):
        if (ride.passengerId != uid) return;
        _selfWrites.add(ride.id);
        await _client.from('rides').insert(rideToInsert(ride));

      case RideUpdated(:final ride):
        _selfWrites.add(ride.id);
        if (ride.passengerId == uid) {
          await _client
              .from('rides')
              .update(ridePassengerPatch(ride))
              .eq('id', ride.id);
        } else if (ride.driverId == uid) {
          await _client
              .from('rides')
              .update(rideDriverPatch(ride))
              .eq('id', ride.id);
        }

      case RideCancelled(:final rideId, :final by, :final reason):
        _selfWrites.add(rideId);
        await _client
            .from('rides')
            .update({
              'status': RideStatus.cancelled.name,
              'cancelled_at': DateTime.now().toUtc().toIso8601String(),
              'cancelled_by': by.name,
              'cancel_reason': reason,
            })
            .eq('id', rideId);

      case OfferCreated(:final offer):
        if (offer.driverId != uid) return;
        _selfWrites.add(offer.id);
        await _client.from('offers').insert(offerToInsert(offer));

      case OfferUpdated(:final offer):
        // Acceptance is the passenger's decision but not the passenger's
        // write: `accept_offer` locks the ride, assigns the driver, settles
        // the fare and declines the losing bids in one transaction. Sending
        // those as four client updates is exactly the race it exists to close.
        if (offer.status == OfferStatus.accepted) {
          await _client.rpc('accept_offer', params: {'p_offer_id': offer.id});
          return;
        }
        if (offer.driverId == uid && offer.status == OfferStatus.withdrawn) {
          _selfWrites.add(offer.id);
          await _client
              .from('offers')
              .update({'status': offer.status.name})
              .eq('id', offer.id);
        }

      case ChatSent(:final message):
        _selfWrites.add(message.id);
        await _client.from('chat_messages').insert(chatToInsert(message, uid));

      case DriverWentOffline(:final driverId):
        if (driverId != uid) return;
        await _client
            .from('driver_locations')
            .update({'online': false})
            .eq('driver_id', driverId);

      case DriverMoved(:final driverId, :final coord, :final bearing):
        if (driverId != uid) return;
        // Upsert rather than insert: there is one row per driver and it is
        // overwritten in place, so a reconnecting driver does not accumulate
        // stale positions.
        await _client
            .from('driver_locations')
            .upsert(
              driverLocationToRow(
                driverId: driverId,
                coord: coord,
                bearing: bearing,
              ),
            );
    }
  }

  /// Marks the driver offline so their car leaves everyone else's map. Called
  /// on sign-out and when the driver goes off duty.
  Future<void> goOffline() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _client
          .from('driver_locations')
          .update({'online': false})
          .eq('driver_id', uid);
    } catch (e) {
      _errors.add(e);
    }
  }

  @override
  void dispose() {
    for (final channel in _channels) {
      unawaited(_client.removeChannel(channel));
    }
    _channels.clear();
    _controller.close();
    _errors.close();
  }
}
