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

  /// An OSRM instance to route against, if there is one.
  ///
  /// Unset, the app estimates distances on-device — straight line times an
  /// urban detour factor — and makes no network call. That estimate is what
  /// makes the whole app work with nothing provisioned, and it is also wrong
  /// for any particular trip, which is why this exists.
  ///
  /// A URL rather than an API key because OSRM is open source and
  /// self-hostable, so routing stays a line of config rather than a vendor
  /// account. The public demo server at router.project-osrm.org is explicitly
  /// not for production traffic; point this at your own.
  static const osrmUrl = String.fromEnvironment('OSRM_URL');

  static const hasRouting = osrmUrl != '';

  /// Where the map's raster tiles come from.
  ///
  /// The default is the OpenStreetMap Foundation's own server, which is what
  /// makes the demo draw a map with nothing provisioned. **It is not a
  /// production tile source.** The OSMF tile usage policy forbids apps with
  /// substantial traffic, is enforced by blocking, and owes you nothing if it
  /// stops answering — a ride-hailing app watching a car move is exactly the
  /// pattern it excludes.
  ///
  /// Point this at your own renderer or a commercial OpenStreetMap provider
  /// before shipping. The data is the same OpenStreetMap data either way,
  /// which is the point of the format being open: the URL changes and nothing
  /// else does.
  static const tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// A Nominatim instance to search for places against, if there is one.
  ///
  /// Unset, destination search reads the offline index in lib/data/places.dart
  /// — a few hundred hand-listed Malaysian places, which works with no network
  /// and cannot find anywhere nobody thought to list. Set, the same search
  /// asks OpenStreetMap for anywhere in the world.
  ///
  /// Nominatim's public instance at nominatim.openstreetmap.org has the same
  /// shape of usage policy as the tile server — one request per second,
  /// absolutely no bulk or heavy use — so it is fine while you are trying this
  /// out and not fine in production. Self-host, or use a provider.
  static const nominatimUrl = String.fromEnvironment('NOMINATIM_URL');

  static const hasGeocoding = nominatimUrl != '';
}
