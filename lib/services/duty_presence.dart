import '../core/duty.dart';
import '../state/session.dart';

/// Decides when the app must stay awake, and says so exactly once per change.
///
/// The rule is small and the ways to get it wrong are not. Asking on every
/// frame would be a channel call per build; asking once and never again would
/// leave the service running after the driver goes off duty, which is both a
/// notification they cannot get rid of and a promise the app is still working
/// when it has stopped. Signing out has to end it too, and a driver who
/// switches the app's language while on duty should not be left looking at an
/// ongoing notification in the language they just left.
///
/// So this tracks what it last *asked for* rather than what it believes is
/// true, and acts only when that changes. A refused start is remembered the
/// same way: the app carries on without the guarantee rather than retrying
/// down a channel that has already said no.
class DutyPresence {
  DutyPresence(
    this._session, {
    required this.service,
    required this.backendLive,
  });

  final SessionStore _session;
  final DutyService service;

  /// Without a backend the only other participants are bots in this same
  /// process, which need nobody awake to run. Staying alive would cost a
  /// driver battery for nothing.
  final bool backendLive;

  /// The text last asked for, or null when the last thing asked for was a
  /// stop. Comparing against this is what makes a rebuild free.
  String? _asked;

  bool _running = false;

  /// Whether the platform said yes. False after a refusal, which is a normal
  /// outcome: the app then works exactly as it did before any of this — fine
  /// in the foreground, at the mercy of the OS behind it.
  bool get isRunning => _running;

  Future<void> sync({required String title, required String body}) async {
    final wanted = backendLive && _session.isDriverOnDuty;
    // One key for both strings, so a change to either restarts the service and
    // neither can drift out of step with the other.
    final want = wanted ? '$title | $body' : null;
    if (want == _asked) return;
    // Set before the await: the post-frame callback that drives this can fire
    // again before the platform answers, and the second call must see that the
    // first already asked.
    _asked = want;

    if (want == null) {
      _running = false;
      await service.stop();
      return;
    }
    _running = await service.start(title: title, body: body);
  }

  /// Ends the service and forgets what was asked, so a later [sync] starts
  /// again from nothing.
  Future<void> dispose() async {
    _asked = null;
    _running = false;
    await service.stop();
  }
}
