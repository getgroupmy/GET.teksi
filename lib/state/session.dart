import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/location.dart';
import '../core/storage.dart';
import '../data/fixtures.dart';
import '../data/places.dart';
import '../models/models.dart';

class Prefs {
  const Prefs({
    this.role = Role.passenger,
    this.darkTheme = true,
    this.driverOnline = false,
    this.language = 'en',
    this.soundEnabled = true,
    this.simulationEnabled = true,
    this.hasSeenIntro = false,
  });

  final Role role;
  final bool darkTheme;

  /// Drivers go on/off duty; only online drivers receive the order feed.
  final bool driverOnline;

  /// Drives MaterialApp's locale. A key with no Malay entry falls back to the
  /// English template rather than throwing, so a screen translated late stays
  /// readable in the meantime.
  final String language;

  /// Whether an OS notification makes a noise. It still appears either way:
  /// a driver's offer belongs in the tray whether or not the phone is meant to
  /// be quiet.
  final bool soundEnabled;

  /// Bot drivers/passengers that make the app demonstrable on one device.
  final bool simulationEnabled;
  final bool hasSeenIntro;

  Prefs copyWith({
    Role? role,
    bool? darkTheme,
    bool? driverOnline,
    String? language,
    bool? soundEnabled,
    bool? simulationEnabled,
    bool? hasSeenIntro,
  }) => Prefs(
    role: role ?? this.role,
    darkTheme: darkTheme ?? this.darkTheme,
    driverOnline: driverOnline ?? this.driverOnline,
    language: language ?? this.language,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    simulationEnabled: simulationEnabled ?? this.simulationEnabled,
    hasSeenIntro: hasSeenIntro ?? this.hasSeenIntro,
  );

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'darkTheme': darkTheme,
    'driverOnline': driverOnline,
    'language': language,
    'soundEnabled': soundEnabled,
    'simulationEnabled': simulationEnabled,
    'hasSeenIntro': hasSeenIntro,
  };

  factory Prefs.fromJson(Map<String, dynamic> json) => Prefs(
    role: json['role'] == 'driver' ? Role.driver : Role.passenger,
    darkTheme: json['darkTheme'] as bool? ?? true,
    driverOnline: json['driverOnline'] as bool? ?? false,
    language: json['language'] as String? ?? 'en',
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    simulationEnabled: json['simulationEnabled'] as bool? ?? true,
    hasSeenIntro: json['hasSeenIntro'] as bool? ?? false,
  );
}

class SessionStore extends ChangeNotifier {
  SessionStore({this.location = const SeededLocationService()}) {
    _user = Store.instance.readJson<AppUser?>(
      _userKey,
      null,
      (json) => AppUser.fromJson(json as Map<String, dynamic>),
    );
    _prefs = Store.instance.readJson<Prefs>(
      _prefsKey,
      const Prefs(),
      (json) => Prefs.fromJson(json as Map<String, dynamic>),
    );
  }

  static const _userKey = 'user';
  static const _prefsKey = 'prefs';

  final LocationService location;

  AppUser? _user;
  late Prefs _prefs;
  LatLng _myLocation = cityCenter;

  AppUser? get user => _user;
  AppUser get requireUser => _user!;
  Prefs get prefs => _prefs;
  LatLng get myLocation => _myLocation;

  Future<void> locate() async {
    final fix = await location.current();
    if (fix != null) {
      _myLocation = fix;
      notifyListeners();
    }
  }

  void setMyLocation(LatLng coord) {
    _myLocation = coord;
    notifyListeners();
  }

  List<DriverDocument> _starterDocuments() => [
    DriverDocument(
      id: uid('doc'),
      kind: DocumentKind.license,
      label: 'Driving licence',
      status: DocumentStatus.approved,
      expiresAt: DateTime.now().add(const Duration(days: 400)),
    ),
    DriverDocument(
      id: uid('doc'),
      kind: DocumentKind.registration,
      label: 'Vehicle registration (Geran)',
      status: DocumentStatus.approved,
    ),
    DriverDocument(
      id: uid('doc'),
      kind: DocumentKind.insurance,
      label: 'Insurance certificate',
      status: DocumentStatus.approved,
      expiresAt: DateTime.now().add(const Duration(days: 200)),
    ),
    DriverDocument(
      id: uid('doc'),
      kind: DocumentKind.psv,
      label: 'PSV / e-hailing permit',
      status: DocumentStatus.pending,
    ),
    DriverDocument(
      id: uid('doc'),
      kind: DocumentKind.selfie,
      label: 'Profile photo verification',
      status: DocumentStatus.approved,
    ),
  ];

  /// [id] is supplied when a backend owns the identity: the local user must
  /// carry the authenticated account's id, because every row-level security
  /// policy compares against it. Without a backend it is minted locally.
  AppUser signIn(String phone, {String? name, String? id}) {
    final existing = _user;
    // Returning to the same number keeps the profile, rating and history —
    // unless the backend says this is a different account, in which case the
    // stored one was a local-only profile and is replaced.
    if (existing != null &&
        existing.phone == phone &&
        (id == null || existing.id == id)) {
      return existing;
    }
    final created = AppUser(
      id: id ?? uuid4(),
      phone: phone,
      name: (name ?? '').trim().isEmpty ? 'Guest' : name!.trim(),
      avatarColor: pickAvatarColor(phone),
      createdAt: DateTime.now(),
      rating: 5,
      ridesTaken: 0,
      walletBalance: 2500,
    );
    _user = created;
    Store.instance.writeJson(_userKey, created.toJson());
    notifyListeners();
    return created;
  }

  void updateUser(AppUser next) {
    _user = next;
    Store.instance.writeJson(_userKey, next.toJson());
    notifyListeners();
  }

  void signOut() {
    _user = null;
    Store.instance.remove(_userKey);
    setPrefs(_prefs.copyWith(role: Role.passenger, driverOnline: false));
  }

  void setPrefs(Prefs next) {
    _prefs = next;
    Store.instance.writeJson(_prefsKey, next.toJson());
    notifyListeners();
  }

  /// Working right now: a driver, in the driver half of the app, on duty.
  ///
  /// All three, and one place to read them. The beacon that publishes a
  /// position and the foreground service that keeps the app alive to publish
  /// it have to agree on when a driver is working; two copies of this
  /// condition is one copy that can be edited alone, and either mistake is
  /// quiet. Reporting a position after going off duty is a privacy failure,
  /// and staying awake after going off duty is a battery one.
  bool get isDriverOnDuty =>
      _user?.isDriver == true &&
      _prefs.role == Role.driver &&
      _prefs.driverOnline;

  void setRole(Role role) => setPrefs(_prefs.copyWith(role: role));

  void becomeDriver(Vehicle vehicle) {
    final u = _user;
    if (u == null) return;
    final profile =
        u.driverProfile?.copyWith(vehicle: vehicle) ??
        DriverProfile(
          vehicle: vehicle,
          rating: 5,
          ridesGiven: 0,
          earnings: 0,
          verified: true,
          documents: _starterDocuments(),
          joinedAt: DateTime.now(),
        );
    updateUser(u.copyWith(driverProfile: profile));
  }

  void updateVehicle({String? plate, String? color}) {
    final u = _user;
    final profile = u?.driverProfile;
    if (u == null || profile == null) return;
    updateUser(
      u.copyWith(
        driverProfile: profile.copyWith(
          vehicle: profile.vehicle.copyWith(plate: plate, color: color),
        ),
      ),
    );
  }

  void saveShortcut({required bool home, required Place place}) {
    final u = _user;
    if (u == null) return;
    updateUser(
      home ? u.copyWith(homePlace: place) : u.copyWith(workPlace: place),
    );
  }

  void clearShortcut({required bool home}) {
    final u = _user;
    if (u == null) return;
    updateUser(
      home ? u.copyWith(clearHome: true) : u.copyWith(clearWork: true),
    );
  }

  void creditWallet(int amount) {
    final u = _user;
    if (u == null) return;
    updateUser(u.copyWith(walletBalance: u.walletBalance + amount));
  }

  bool debitWallet(int amount) {
    final u = _user;
    if (u == null || u.walletBalance < amount) return false;
    updateUser(u.copyWith(walletBalance: u.walletBalance - amount));
    return true;
  }

  void recordPassengerTrip() {
    final u = _user;
    if (u == null) return;
    updateUser(u.copyWith(ridesTaken: u.ridesTaken + 1));
  }

  /// The trip happened and the driver's count should reflect it, but the money
  /// was moved by the server. Splitting this out keeps the tally honest without
  /// the device inventing a balance it does not own.
  void recordDriverTrip() {
    final u = _user;
    final profile = u?.driverProfile;
    if (u == null || profile == null) return;
    updateUser(
      u.copyWith(
        driverProfile: profile.copyWith(ridesGiven: profile.ridesGiven + 1),
      ),
    );
  }

  void recordDriverEarning(int amount) {
    final u = _user;
    final profile = u?.driverProfile;
    if (u == null || profile == null) return;
    updateUser(
      u.copyWith(
        driverProfile: profile.copyWith(
          earnings: profile.earnings + amount,
          ridesGiven: profile.ridesGiven + 1,
        ),
        walletBalance: u.walletBalance + amount,
      ),
    );
  }
}
