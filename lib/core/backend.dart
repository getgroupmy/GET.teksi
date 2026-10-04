import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'bus.dart';
import 'config.dart';
import 'rows.dart';
import 'supabase_transport.dart';

/// Connects the app to its backend, when it has one.
///
/// The app is designed to be fully functional without this: unconfigured, it
/// keeps the on-device transport, the simulated marketplace and local
/// persistence, and every screen behaves exactly as it does in the demo. That
/// is not a fallback bolted on for convenience — it is what lets the whole UI
/// be developed and tested with no infrastructure at all.
///
/// Configured, the same build signs in with a real phone OTP and its rides,
/// bids and messages travel through Postgres to other devices.
class Backend {
  const Backend._();

  static SupabaseClient? _client;
  static SupabaseTransport? _transport;

  /// True once a backend is configured *and* reachable.
  static bool get isLive => _client != null;

  static SupabaseClient get client {
    final c = _client;
    if (c == null) {
      throw StateError(
        'No backend is configured. Guard backend calls with Backend.isLive, '
        'or build with --dart-define=SUPABASE_URL=… and SUPABASE_ANON_KEY=….',
      );
    }
    return c;
  }

  /// Errors from the live transport — rejected writes, dropped subscriptions.
  /// Empty when running locally, so listeners need no special case.
  static Stream<Object> get errors =>
      _transport?.errors ?? const Stream<Object>.empty();

  /// Never throws. A backend that is misconfigured or unreachable at startup
  /// leaves the app on its local transport, because a rider who cannot connect
  /// is better served by an app that opens than by one that will not start.
  static Future<void> init() async {
    if (!AppConfig.hasBackend) return;
    try {
      final instance = await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
        // Realtime is the point of the integration; a ride whose position
        // updates arrive a second late is a ride the passenger has stopped
        // trusting.
        realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
      );
      _client = instance.client;
      final transport = SupabaseTransport(instance.client);
      _transport = transport;
      setTransport(transport);
    } catch (_) {
      _client = null;
      _transport = null;
    }
  }

  /// The server's view of the signed-in user's money: the cached balance and
  /// the ledger it was derived from.
  ///
  /// Read-only by construction — the wallet table grants `select` and nothing
  /// else, so there is no client-side write to offer here even if one were
  /// wanted. Entries appear because a ride completed, not because an app asked.
  static Future<({int balance, List<Txn> entries})?> fetchWallet() async {
    final uid = _client?.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final profile = await client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', uid)
          .single();
      final rows = await client
          .from('wallet_transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(120);
      return (
        balance: (profile['wallet_balance'] as num?)?.toInt() ?? 0,
        entries: (rows as List)
            .map((r) => walletTxnFromRow((r as Map).cast<String, dynamic>()))
            .toList(),
      );
    } catch (e) {
      _transport?.report(e);
      return null;
    }
  }

  /// Writes the columns a client is allowed to write on its own profile.
  ///
  /// Deliberately not a whole-row upsert: the guard trigger refuses the wallet
  /// balance, the ratings, the trip counts and the verification flag, so
  /// sending them would turn every save into a rejected statement. The caller
  /// decides what those columns are; this only carries them.
  static Future<void> saveProfile(
    String userId,
    Map<String, dynamic> columns,
  ) async {
    if (!isLive) return;
    await client.from('profiles').update(columns).eq('id', userId);
  }

  // ---------------------------------------------------------------------------
  // Auth
  //
  // Phone-first, matching the app's sign-in flow. Supabase sends and verifies
  // the code, so the OTP screen stops being a prompt that accepts anything.
  // ---------------------------------------------------------------------------

  static Future<void> sendOtp(String phone) =>
      client.auth.signInWithOtp(phone: _e164(phone));

  static Future<AuthResponse> verifyOtp(String phone, String token) => client
      .auth
      .verifyOTP(phone: _e164(phone), token: token, type: OtpType.sms);

  static Future<void> signOut() async {
    await _transport?.goOffline();
    if (isLive) await client.auth.signOut();
  }

  /// Supabase requires E.164. The app collects Malaysian numbers in local form
  /// ("012-345 6789"), so the country code is applied here rather than being
  /// demanded of the user.
  static String _e164(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('60')) return '+$digits';
    return '+60${digits.startsWith('0') ? digits.substring(1) : digits}';
  }
}
