import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../models/models.dart';
import '../state/rides.dart';
import '../state/session.dart';

/// Publishes a real driver's position, so the passenger tracking them sees a
/// car that moves.
///
/// Everything else for this already existed and none of it was connected: the
/// `driver_locations` table, the policy letting a driver write their own row,
/// the realtime subscription other devices listen on, the transport's arm that
/// upserts a [DriverMoved], and the store's arm that applies one on receipt.
/// What was missing was anything that ever emitted the event. Against a live
/// backend a passenger watched a driver who never moved, because no code path
/// on the driver's phone ever said where it was.
///
/// The simulated fleet does not come through here. Bot drivers move by writing
/// straight into the store, which is right — they exist only in the process
/// that invented them, and publishing them would scatter imaginary cars across
/// other people's maps.
class DriverBeacon {
  DriverBeacon(
    this._session,
    this._rides, {
    this.idleInterval = const Duration(seconds: 20),
    this.activeInterval = const Duration(seconds: 5),
    this.minMoveMetres = 20,
  });

  final SessionStore _session;
  final RidesStore _rides;

  /// Online but carrying nobody. The position still matters — it is what puts
  /// this driver in a passenger's "nearby" list — but nobody is watching it
  /// move, so sampling hard would spend battery to no end.
  final Duration idleInterval;

  /// Carrying a passenger, or on the way to one. Somebody has the map open and
  /// is deciding whether to walk outside.
  final Duration activeInterval;

  /// How far the device must have moved before a fix is treated as movement.
  ///
  /// A stationary phone does not report a stationary position: consumer GPS
  /// wanders by a few metres indefinitely. Publishing that wander would send a
  /// stream of writes that say nothing, and — worse — recomputing the bearing
  /// from two jitter samples points the car in a random direction, so a parked
  /// car spins on the passenger's map. Below this threshold the beacon holds
  /// its last heading and stays quiet.
  final double minMoveMetres;

  Timer? _timer;
  Duration? _cadence;
  LatLng? _lastPublished;
  double _bearing = 0;
  bool _reading = false;

  /// Bumped by [stop]. A read that was already awaiting a fix when the driver
  /// went off duty finds its generation stale and drops the answer.
  ///
  /// Without this, `stop()` only cancels the next tick: a fix already in flight
  /// still publishes, so a driver who goes offline reports their position once
  /// more afterwards. That is the one thing going offline has to actually
  /// prevent, and a timer cancel alone does not prevent it.
  int _generation = 0;

  bool get isRunning => _timer != null;

  /// The last position actually sent, or null if nothing has been. Exposed for
  /// tests rather than for the UI.
  LatLng? get lastPublished => _lastPublished;

  void start() {
    if (isRunning) return;
    // Report immediately rather than after a full interval: a driver who has
    // just gone online should appear on the map now, not in twenty seconds.
    unawaited(_sample());
    _restart(_intervalNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _cadence = null;
    _lastPublished = null;
    _generation++;
  }

  void dispose() => stop();

  void _restart(Duration interval) {
    _timer?.cancel();
    _cadence = interval;
    _timer = Timer.periodic(interval, (_) => unawaited(_sample()));
  }

  Duration _intervalNow() {
    final user = _session.user;
    if (user == null) return idleInterval;
    final active = _rides.activeRideFor(user.id, Role.driver);
    return active == null ? idleInterval : activeInterval;
  }

  Future<void> _sample() async {
    // A slow fix must not stack up behind itself. The location call is bounded
    // by its own timeout, but on a bad indoor fix that timeout can be longer
    // than the active interval, and two overlapping reads would publish out of
    // order.
    if (_reading) return;
    _reading = true;
    final generation = _generation;
    try {
      final wanted = _intervalNow();
      if (_cadence != null && wanted != _cadence) _restart(wanted);

      final user = _session.user;
      if (user == null) return;

      final fix = await _session.location.current();
      // The driver may have gone off duty while this fix was being taken.
      if (generation != _generation) return;
      // Null means permission refused, location off, or no fix in time. None of
      // those is worth reporting: the last known position is better than none,
      // and the rider is not owed an error for a thing they can still do.
      if (fix == null) return;

      // The driver's own map should follow the fix even when the position is
      // not worth publishing.
      _session.setMyLocation(fix);

      final previous = _lastPublished;
      if (previous != null) {
        final movedMetres = haversineKm(previous, fix) * 1000;
        if (movedMetres < minMoveMetres) return;
        // Only now is the heading meaningful: two fixes far enough apart that
        // the line between them is travel rather than noise.
        _bearing = bearingBetween(previous, fix);
      }

      _lastPublished = fix;
      _rides.reportDriverPosition(user.id, fix, _bearing);
    } finally {
      _reading = false;
    }
  }
}
