import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/screens/auth/intro_screen.dart';
import 'package:get_teksi/screens/auth/otp_screen.dart';
import 'package:get_teksi/screens/auth/phone_screen.dart';
import 'package:get_teksi/screens/auth/profile_setup_screen.dart';
import 'package:get_teksi/screens/driver/driver_home_screen.dart';
import 'package:get_teksi/screens/driver/earnings_screen.dart';
import 'package:get_teksi/screens/driver/onboarding_screen.dart';
import 'package:get_teksi/screens/driver/order_detail_screen.dart';
import 'package:get_teksi/screens/driver/vehicle_screen.dart';
import 'package:get_teksi/screens/passenger/destination_search_screen.dart';
import 'package:get_teksi/screens/passenger/passenger_home_screen.dart';
import 'package:get_teksi/screens/shared/chat_screen.dart';
import 'package:get_teksi/screens/shared/history_screen.dart';
import 'package:get_teksi/screens/shared/menu_screen.dart';
import 'package:get_teksi/screens/shared/notifications_screen.dart';
import 'package:get_teksi/screens/shared/places_screen.dart';
import 'package:get_teksi/screens/shared/profile_screen.dart';
import 'package:get_teksi/screens/shared/promos_screen.dart';
import 'package:get_teksi/screens/shared/rate_screen.dart';
import 'package:get_teksi/screens/shared/ride_detail_screen.dart';
import 'package:get_teksi/screens/shared/safety_screen.dart';
import 'package:get_teksi/screens/shared/settings_screen.dart';
import 'package:get_teksi/screens/shared/wallet_screen.dart';
import 'package:get_teksi/state/draft.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:get_teksi/theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's screens, with everything they need to be laid out in a test.
///
/// Shared because there are two gates that walk every screen — one for layout
/// at a large text size, one for what a screen reader is given — and a second
/// copy of this would drift from the first the next time a screen is added.
/// A screen missing from here is a screen neither gate covers, which is the
/// failure mode worth designing against.
/// A phone, not the 800x600 the test harness defaults to. Layout at large text
/// depends on the width it is given, and 800 logical pixels wide is a width no
/// phone has — it would hide exactly the overflows this is looking for.
const phoneSize = Size(393, 852);

/// What `MaterialApp.router` wraps every screen in, reproduced here. Screens
/// are designed as a phone-shaped column and never see more than 480 logical
/// pixels, so testing them wider would be testing a layout that never ships.
const maxColumnWidth = 480.0;

const klcc = LatLng(3.1578, 101.7123);
const midValley = LatLng(3.1177, 101.6771);

Place place(String name, LatLng at) =>
    Place(id: uid('pl'), name: name, address: '$name, Kuala Lumpur', coord: at);

/// A ride for the screens that are addressed by one. Deliberately not a
/// minimal ride: the long names, the comment and the options are all text that
/// has to fit somewhere, and a screen that lays out cleanly with empty fields
/// proves very little.
Ride buildRide() {
  final now = DateTime.now();
  return Ride(
    id: uuid4(),
    passengerId: uuid4(),
    passengerName: 'Nurul Ain binti Abdullah',
    passengerAvatarColor: 0xFF4CAF50,
    passengerRating: 4.8,
    service: ServiceType.city,
    vehicleClass: VehicleClass.comfort,
    pickup: place('KLCC Tower 2 North Entrance', klcc),
    dropoff: place('Mid Valley Megamall South Court', midValley),
    askingPrice: 1850,
    recommendedPrice: 2000,
    distanceKm: 8.4,
    durationMinutes: 22,
    paymentMethod: PaymentMethod.wallet,
    passengerCount: 2,
    options: const [RideOption.luggage, RideOption.airCon],
    status: RideStatus.searching,
    createdAt: now.subtract(const Duration(minutes: 4)),
    updatedAt: now,
    priceRaises: 1,
    comment: 'Waiting by the north entrance, blue jacket',
    routeGeometry: const [klcc, midValley],
  );
}

/// One app's worth of state, rebuilt for each test.
class ScreenFixture {
  late SessionStore session;
  late RidesStore rides;
  late DraftStore draft;

  /// A published ride, for the screens addressed by one.
  late String rideId;

  /// Call from `setUp`.
  Future<void> reset() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    session = SessionStore();
    // Signed in, and a driver. Most screens read `requireUser`, and the
    // driver screens read the profile under it — a signed-out session makes
    // them throw on a null check long before anything has been laid out,
    // which says nothing about text size.
    final user = session.signIn(
      '+60123456789',
      name: 'Nurul Ain binti Abdullah',
    );
    session.updateUser(
      user.copyWith(
        email: 'nurul.ain.binti.abdullah@example.com',
        driverProfile: DriverProfile(
          vehicle: const Vehicle(
            make: 'Perodua',
            model: 'Bezza 1.3 Premium',
            year: 2021,
            color: 'Granite Grey',
            plate: 'WXY 1234',
            vehicleClass: VehicleClass.comfort,
            seats: 4,
          ),
          rating: 4.9,
          ridesGiven: 1204,
          earnings: 1894500,
          verified: true,
          documents: const [],
          joinedAt: DateTime.now().subtract(const Duration(days: 400)),
        ),
      ),
    );
    rides = RidesStore(session);
    draft = DraftStore();
    rideId = rides.publishRide(buildRide()).id;
  }

  /// Every screen in the app, by the name the failure should mention.
  Map<String, Widget Function()> screens() => {
    'IntroScreen': () => const IntroScreen(),
    'PhoneScreen': () => const PhoneScreen(),
    'OtpScreen': () => const OtpScreen(phone: '+60123456789'),
    'ProfileSetupScreen': () => const ProfileSetupScreen(phone: '+60123456789'),
    'PassengerHomeScreen': () => const PassengerHomeScreen(),
    'DestinationSearchScreen': () => const DestinationSearchScreen(),
    'DriverHomeScreen': () => const DriverHomeScreen(),
    'DriverOnboardingScreen': () => const DriverOnboardingScreen(),
    'EarningsScreen': () => const EarningsScreen(),
    'VehicleScreen': () => const VehicleScreen(),
    'OrderDetailScreen': () => OrderDetailScreen(rideId: rideId),
    'RideDetailScreen': () => RideDetailScreen(rideId: rideId),
    'ChatScreen': () => ChatScreen(rideId: rideId),
    'RateScreen': () => RateScreen(rideId: rideId),
    'SafetyScreen': () => SafetyScreen(rideId: rideId),
    'MenuScreen': () => const MenuScreen(),
    'ProfileScreen': () => const ProfileScreen(),
    'SettingsScreen': () => const SettingsScreen(),
    'WalletScreen': () => const WalletScreen(),
    'HistoryScreen': () => const HistoryScreen(),
    'NotificationsScreen': () => const NotificationsScreen(),
    'PlacesScreen': () => const PlacesScreen(),
    'PromosScreen': () => const PromosScreen(),
  };

  /// The tree the app puts around a screen: its providers, its theme, its
  /// localisations, and the phone-width column from `MaterialApp.router`'s
  /// builder in main.dart. [scale] multiplies the system text size.
  Widget wrap(Widget screen, {double scale = 1.0, bool dark = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionStore>.value(value: session),
        ChangeNotifierProvider<RidesStore>.value(value: rides),
        ChangeNotifierProvider<DraftStore>.value(value: draft),
        Provider<Notifier>.value(value: const SilentNotifier()),
      ],
      child: MaterialApp(
        theme: buildTheme(dark: dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxColumnWidth),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  /// A phone-sized surface, not the harness's default 800x600, which is a
  /// width no phone has.
  void sizeAsPhone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = phoneSize;
    addTearDown(tester.view.reset);
  }
}
