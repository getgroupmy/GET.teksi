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

/// Every screen, laid out at double the system text size.
///
/// The accessibility audit (docs/UI-UX-AUDIT.md) fixed the rows that were
/// obviously brittle and recorded the rest as not done: "the app has not been
/// walked end to end at maximum system text size". This walks it, on every
/// build, so that the answer stops depending on whether anyone remembered to
/// look.
///
/// Worth saying what the failure actually looks like, because it is not a
/// crash. A `Row` of two labels that no longer fit paints a yellow-and-black
/// stripe in debug and silently clips in release — the words are simply gone,
/// with nothing in any log. Someone who has turned text size up is exactly the
/// person who cannot read what is left.
///
/// The app does not clamp the scale anywhere: `MaterialApp.router` in
/// main.dart passes the platform's value straight through, so 2.0 is a setting
/// a real user can choose. Android's accessibility slider reaches it, and
/// iOS's larger accessibility sizes go beyond — so this is a floor, not a
/// ceiling.

/// A phone, not the 800x600 the test harness defaults to. Layout at large text
/// depends on the width it is given, and 800 logical pixels wide is a width no
/// phone has — it would hide exactly the overflows this is looking for.
const _phone = Size(393, 852);

/// What `MaterialApp.router` wraps every screen in, reproduced here. Screens
/// are designed as a phone-shaped column and never see more than 480 logical
/// pixels, so testing them wider would be testing a layout that never ships.
const _maxColumnWidth = 480.0;

const _klcc = LatLng(3.1578, 101.7123);
const _midValley = LatLng(3.1177, 101.6771);

Place _place(String name, LatLng at) =>
    Place(id: uid('pl'), name: name, address: '$name, Kuala Lumpur', coord: at);

/// A ride for the screens that are addressed by one. Deliberately not a
/// minimal ride: the long names, the comment and the options are all text that
/// has to fit somewhere, and a screen that lays out cleanly with empty fields
/// proves very little.
Ride _ride() {
  final now = DateTime.now();
  return Ride(
    id: uuid4(),
    passengerId: uuid4(),
    passengerName: 'Nurul Ain binti Abdullah',
    passengerAvatarColor: 0xFF4CAF50,
    passengerRating: 4.8,
    service: ServiceType.city,
    vehicleClass: VehicleClass.comfort,
    pickup: _place('KLCC Tower 2 North Entrance', _klcc),
    dropoff: _place('Mid Valley Megamall South Court', _midValley),
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
    routeGeometry: const [_klcc, _midValley],
  );
}

void main() {
  late SessionStore session;
  late RidesStore rides;
  late DraftStore draft;
  late String rideId;

  setUp(() async {
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
    rideId = rides.publishRide(_ride()).id;
  });

  /// Lays the screen out the way the app does, at [scale] times the normal
  /// text size, and returns a description of the first complaint, or null.
  ///
  /// The complaint is collected through `FlutterError.onError` rather than
  /// `tester.takeException()` because `takeException` hands back only the
  /// message — "overflowed by 305 pixels on the right" — and then whoever
  /// reads the failure has to go and find the row by hand. The error's
  /// `debugCreator` carries the widget ancestry, which names it.
  Future<String?> layout(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    required bool dark,
  }) async {
    final complaints = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final creator = details.informationCollector
          ?.call()
          .map((node) => node.toString())
          .firstWhere(
            (line) => line.startsWith('debugCreator:'),
            orElse: () => '',
          );
      complaints.add(
        creator == null || creator.isEmpty
            ? '${details.exception}'
            : '${details.exception}\n    in ${creator.substring('debugCreator: '.length)}',
      );
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = _phone;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
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
                constraints: const BoxConstraints(maxWidth: _maxColumnWidth),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
    // Overflow is reported from paint, so one frame is enough to catch it —
    // but a screen that starts an animation or a timer settles into a
    // different layout, and that one has to fit as well. Not pumpAndSettle:
    // the map and the offer countdown never stop, so it would time out.
    await tester.pump(const Duration(milliseconds: 350));
    FlutterError.onError = previousOnError;
    return complaints.isEmpty ? null : complaints.first;
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

  group('at the normal text size', () {
    // The control. If a screen cannot lay out at 1.0 then the 2.0 failure
    // below says nothing about text size, and this is where to look first.
    screens().forEach((name, build) {
      testWidgets('$name lays out', (tester) async {
        final error = await layout(tester, build(), scale: 1.0, dark: true);
        expect(error, isNull, reason: '$name at 1.0x: $error');
      });
    });
  });

  group('at double the text size', () {
    screens().forEach((name, build) {
      testWidgets('$name lays out', (tester) async {
        final error = await layout(tester, build(), scale: 2.0, dark: true);
        expect(
          error,
          isNull,
          reason:
              '$name overflows at 2.0x text scale. Someone who has turned '
              'text size up loses whatever is past the edge, with no error '
              'anywhere in release. $error',
        );
      });
    });
  });

  group('the gate itself', () {
    // Without this the suite above could pass because overflow is not being
    // reported at all — a mistake in `layout` would read as 23 clean screens.
    testWidgets('catches an overflow that is really there', (tester) async {
      final error = await layout(
        tester,
        // 600 logical pixels of text in a column that is at most 480 wide.
        Scaffold(
          body: Row(
            children: [Container(width: 600, height: 20, color: Colors.red)],
          ),
        ),
        scale: 1.0,
        dark: true,
      );
      expect(
        error,
        isNotNull,
        reason:
            'a deliberate overflow was not reported, so the suite above '
            'is not testing anything',
      );
      expect(error, contains('overflowed'));
      // And that the ancestry made it into the message, which is the only
      // thing that turns a failure into a place to look.
      expect(error, contains('in Row'));
    });
  });
}
