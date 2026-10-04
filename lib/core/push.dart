import 'backend.dart';
import 'push_channel.dart' if (dart.library.js_interop) 'push_web.dart';

export 'push_channel.dart'
    if (dart.library.js_interop) 'push_web.dart'
    show readPushAddress;

/// Where a push notification for this device should be sent.
///
/// The two platforms give different shapes and this holds both, because they
/// are the same fact at different lengths. APNs hands back a device token.
/// Web Push hands back an endpoint URL plus the two keys a sender encrypts
/// to — Web Push is encrypted end to end, and the push service relaying it
/// never sees the payload.
class PushAddress {
  const PushAddress({
    required this.platform,
    required this.token,
    this.p256dh,
    this.auth,
  });

  /// 'ios' or 'web'. Matches the check constraint on `push_tokens.platform`.
  final String platform;

  /// The APNs device token, or the Web Push endpoint URL.
  final String token;

  /// Web Push only. Null on iOS.
  final String? p256dh;
  final String? auth;

  /// True when this is a shape the server will accept.
  ///
  /// The same rule as the `push_tokens_web_has_keys` constraint, checked here
  /// as well as there on purpose. The database refusing a row is the right
  /// last line, but by then the failure is a rejected insert on a device
  /// nobody is watching; this turns it into something a test can catch.
  bool get isDeliverable => platform == 'web'
      ? (p256dh != null && auth != null)
      : (p256dh == null && auth == null);

  /// The row to upsert. Keyed on (platform, token), so a device that
  /// re-registers updates rather than accumulating, and one handed to a
  /// different account moves with it.
  Map<String, dynamic> toRow(String userId) => {
    'user_id': userId,
    'platform': platform,
    'token': token,
    'p256dh': p256dh,
    'auth': auth,
  };
}

/// Tells the backend where to reach this device.
///
/// Silent and harmless in every case where it cannot work: no backend
/// configured, nobody signed in, a platform with no transport, permission
/// refused, or a push service that did not answer. None of those is an error
/// the person using the app can act on, and a ride-hailing app that fails to
/// open because a notification could not be arranged would be the worse bug.
///
/// Android is deliberately not covered. docs/PUSH.md has the reasoning: every
/// GMS-free Android route costs either a vendor account and a build flavour,
/// or a server with an uptime obligation, and the Android case that matters
/// most — a driver waiting for orders — is already held open by DutyService.
Future<bool> registerForPush({required String userId}) async {
  if (!Backend.isLive || userId.isEmpty) return false;

  final PushAddress? address;
  try {
    address = await readPushAddress();
  } catch (_) {
    return false;
  }
  if (address == null || !address.isDeliverable) return false;

  try {
    await Backend.client
        .from('push_tokens')
        .upsert(address.toRow(userId), onConflict: 'platform,token');
    return true;
  } catch (_) {
    // A rejected upsert means this device will not be reached. That is worth
    // nothing to the person holding it, so it stays quiet here and shows up
    // as an absence of notifications rather than as an error.
    return false;
  }
}
