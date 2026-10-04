import 'dart:async';

import '../models/models.dart';
import '../state/session.dart';

/// Sends the profile to the server, so the server's idea of who you are
/// matches the app's.
///
/// Sign-up pushed a name, an email and a colour, and nothing after that ever
/// pushed anything. Becoming a driver was the expensive omission, because
/// `is_driver` is not decoration on the server — it is the condition on two
/// policies:
///
///   drivers read the open order feed   using (status = 'searching' and is_driver())
///   drivers bid as themselves          with check (driver_id = auth.uid() and is_driver())
///
/// So a driver who finished onboarding in the app and went on duty against a
/// live backend saw an empty order feed and had every bid rejected. Silently,
/// both times: row-level security answers a read with no rows and a write with
/// a refusal, and neither is an error the app would think to show.
///
/// This listens rather than being called, on purpose. Three screens already
/// mutate the profile — onboarding, the vehicle editor, the profile editor —
/// and a fourth is one feature away. A push wired into each is a push the
/// fourth will forget.
class ProfileSync {
  ProfileSync(
    this._session, {
    required this.push,
    this.settle = const Duration(milliseconds: 400),
  });

  final SessionStore _session;

  /// How the columns reach the backend. Injected so this class holds no
  /// Supabase, which is what keeps it testable without a network or bindings.
  final Future<void> Function(String userId, Map<String, dynamic> columns) push;

  /// SessionStore notifies for things that are not the profile — a new
  /// position most often — so a write per notification would be mostly writes
  /// of nothing. Waiting for the changes to settle also collapses a burst,
  /// such as onboarding setting a role and a vehicle in the same breath.
  final Duration settle;

  Timer? _timer;
  bool _listening = false;

  /// The last payload actually sent. Comparing against this is what makes an
  /// unrelated notification cost nothing.
  Map<String, dynamic>? _sent;

  bool get isRunning => _listening;

  void start() {
    if (_listening) return;
    _listening = true;
    _session.addListener(_onChanged);
    // Push immediately as well as on change: the reason to start is usually
    // that someone just signed in, and their profile may already differ from
    // whatever the server has.
    _onChanged();
  }

  void stop() {
    if (!_listening) return;
    _session.removeListener(_onChanged);
    _listening = false;
    _timer?.cancel();
    _timer = null;
    _sent = null;
  }

  void dispose() => stop();

  void _onChanged() {
    _timer?.cancel();
    _timer = Timer(settle, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    final user = _session.user;
    if (user == null) return;

    final columns = _columnsFor(user);
    if (_sameAsSent(columns)) return;

    try {
      await push(user.id, columns);
      _sent = columns;
    } catch (_) {
      // Leave _sent alone so the next change tries again. A profile that is a
      // few seconds stale on the server is worth far less noise than a dialog
      // over a write the user never asked for.
    }
  }

  /// Only the columns a client is allowed to write.
  ///
  /// The rest — the wallet balance, the ratings, the trip counts, the
  /// verification flag — are refused by a guard trigger, and including them
  /// would turn every push into a rejected statement. The app keeps local
  /// copies of some of those for the demo; they stop at the device.
  static Map<String, dynamic> _columnsFor(AppUser user) => {
    'name': user.name,
    'email': user.email,
    'avatar_color': user.avatarColor,
    'is_driver': user.isDriver,
    'vehicle': user.driverProfile?.vehicle.toJson(),
  };

  bool _sameAsSent(Map<String, dynamic> columns) {
    final sent = _sent;
    if (sent == null) return false;
    for (final entry in columns.entries) {
      if (sent[entry.key].toString() != entry.value.toString()) return false;
    }
    return true;
  }
}
