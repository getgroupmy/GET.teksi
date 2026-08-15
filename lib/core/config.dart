/// Build-time configuration.
///
/// The app runs with no backend at all by default: leave these unset and it
/// keeps the on-device transport, the simulated marketplace and local
/// persistence, which is what makes the demo work with nothing to provision.
/// Supply both values and the same build talks to a real Supabase project.
///
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
/// ```
///
/// These are compile-time constants rather than a `.env` file read at runtime
/// because `String.fromEnvironment` is const-folded, so the values are also
/// available in const contexts and tree-shaking can drop the unreachable
/// branch entirely. The anon key is a public identifier — it is safe in a
/// shipped binary precisely because row-level security, not key secrecy, is
/// what protects the data.
class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase renamed the anon key to the publishable key. Both spellings are
  /// accepted so a project set up under either convention works unchanged.
  static const supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  /// True when a backend is configured. Both halves are required: a URL with
  /// no key would fail at the first request rather than at startup, which is a
  /// much worse place to discover a misconfiguration.
  static const hasBackend = supabaseUrl != '' && supabaseKey != '';
}
