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

/// Both locales the app ships, so a gate that walks every screen walks every
/// screen in both. Malay is not a translation of the layout's spare room: it
/// is 17% more characters overall, longer in 70% of the shared strings, and
/// "RM5 off any trip" becomes "Potongan RM5 untuk mana-mana perjalanan" —
/// 144% longer, in a promo pill.
const appLocales = [Locale('en'), Locale('ms')];

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

/// A finished ride, for the screens that show a list of them.
///
/// [asDriver] decides which side of the ride the signed-in user is on, which
/// is what `historyFor` filters by — so both are seeded and the history and
/// earnings screens are populated whichever role the session is in.
Ride buildFinishedRide({
  required String userId,
  required bool asDriver,
  required RideStatus status,
  DateTime? finishedAt,
}) {
  final now = DateTime.now();
  final ended = finishedAt ?? now.subtract(const Duration(days: 2));
  final started = ended.subtract(const Duration(minutes: 65));
  return Ride(
    id: uuid4(),
    passengerId: asDriver ? uuid4() : userId,
    passengerName: 'Siti Nurhaliza binti Tarudin',
    passengerAvatarColor: 0xFF7E57C2,
    passengerRating: 4.9,
    service: ServiceType.city,
    vehicleClass: VehicleClass.comfort,
    // Long on purpose. Malaysian place names of this length are ordinary, and
    // a history row that fits "KLCC" proves nothing about the one that has to
    // show this.
    pickup: place('Kuala Lumpur International Airport Terminal 2', klcc),
    dropoff: place('Bangsar South City Park Residences Block C', midValley),
    askingPrice: 5500,
    finalPrice: status == RideStatus.completed ? 5800 : null,
    recommendedPrice: 6000,
    distanceKm: 48.6,
    durationMinutes: 54,
    paymentMethod: PaymentMethod.wallet,
    passengerCount: 3,
    options: const [RideOption.luggage, RideOption.airCon],
    status: status,
    createdAt: started,
    updatedAt: now,
    priceRaises: 0,
    driverId: asDriver ? userId : uuid4(),
    driverName: 'Muhammad Firdaus bin Abdul Rahman',
    driverAvatarColor: 0xFF26A69A,
    driverRating: 4.95,
    driverVehicle: const Vehicle(
      make: 'Perodua',
      model: 'Bezza 1.3 Premium',
      year: 2021,
      color: 'Granite Grey',
      plate: 'WXY 1234',
      vehicleClass: VehicleClass.comfort,
      seats: 4,
    ),
    acceptedAt: started.add(const Duration(minutes: 2)),
    arrivedAt: started.add(const Duration(minutes: 9)),
    startedAt: started.add(const Duration(minutes: 11)),
    completedAt: status == RideStatus.completed ? ended : null,
    cancelledAt: status == RideStatus.cancelled ? ended : null,
    cancelledBy: status == RideStatus.cancelled ? CancelledBy.passenger : null,
    cancelReason: status == RideStatus.cancelled
        ? 'Driver could not reach the pickup point'
        : null,
    routeGeometry: const [klcc, midValley],
    // Both sides rated, and that is load-bearing. Both home screens call
    // `rideAwaitingRating` and push to `/rate/...` from a post-frame callback
    // when a completed ride has no rating from the signed-in side. There is
    // no GoRouter in this harness, so one unrated completed ride does not
    // make DriverHome lay out differently — it makes it throw "No GoRouter
    // found in context" before laying out at all, taking the top-bar and
    // semantics gates down with it.
    ratingByPassenger: status == RideStatus.completed
        ? RideRating(
            stars: 5,
            tags: const ['Clean car', 'Safe driving'],
            comment:
                'Helped with the suitcases and took the coastal road to '
                'avoid the jam.',
            createdAt: started.add(const Duration(minutes: 70)),
          )
        : null,
    ratingByDriver: status == RideStatus.completed
        ? RideRating(
            stars: 5,
            tags: const ['On time', 'Polite'],
            createdAt: started.add(const Duration(minutes: 72)),
          )
        : null,
    tip: status == RideStatus.completed ? 500 : null,
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
    _populate(user.id);
  }

  /// The lists.
  ///
  /// Without this, five screens render an `EmptyState` or close to it, and
  /// the rows that actually pair a label with a value — a notification, a
  /// wallet transaction, a chat bubble, a history entry, an earnings line —
  /// are never laid out at all. Measured before this existed:
  /// NotificationsScreen rendered three `Text`s and **zero** `Row`s, so the
  /// text-scale gate could not have failed on it whatever the text size, and
  /// it still counted as one of the twenty-three screens both gates report.
  ///
  /// This is the same point the comment on `buildRide` already makes — "a
  /// screen that lays out cleanly with empty fields proves very little" —
  /// applied to the screens that are a list rather than a form.
  void _populate(String userId) {
    // EarningsScreen opens on `_Period.today`, whose cutoff is midnight this
    // morning, so a trip finished two days ago leaves it on its empty state —
    // which is where it sat while counting as a covered screen.
    //
    // Clamped to just after midnight rather than a flat `now - 30 minutes`.
    // For a run between 00:00 and 00:30 that subtraction lands yesterday, the
    // screen empties again, and the gate goes quiet — once a month, in CI, at
    // an hour nobody is watching.
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final earlier = now.subtract(const Duration(minutes: 30));
    final finishedToday = earlier.isAfter(midnight)
        ? earlier
        : midnight.add(const Duration(minutes: 1));

    rides.publishRide(
      buildFinishedRide(
        userId: userId,
        asDriver: true,
        status: RideStatus.completed,
        finishedAt: finishedToday,
      ),
    );
    // One each side of an older trip, because `historyFor` filters by role
    // and the session's role defaults to passenger.
    for (final asDriver in [true, false]) {
      rides.publishRide(
        buildFinishedRide(
          userId: userId,
          asDriver: asDriver,
          status: RideStatus.completed,
        ),
      );
    }
    // A cancelled ride too. History draws it differently from a completed
    // one — a cancel icon in danger red, the word "Cancelled" where the fare
    // label goes, and the fare struck through — so without one in the fixture
    // that whole branch of the row never renders.
    rides.publishRide(
      buildFinishedRide(
        userId: userId,
        asDriver: false,
        status: RideStatus.cancelled,
      ),
    );

    // Every kind, because each one picks its own icon, colour and sign, and
    // a list that only ever holds one kind tests one branch of that.
    const money = <TransactionKind, (int, String)>{
      TransactionKind.rideEarning: (5800, 'Trip from KLIA Terminal 2'),
      TransactionKind.ridePayment: (-1850, 'Trip to Mid Valley Megamall'),
      TransactionKind.topup: (10000, 'Top-up via FPX — Maybank2u'),
      TransactionKind.payout: (-25000, 'Weekly payout to Maybank ****4321'),
      TransactionKind.tip: (500, 'Tip from Siti Nurhaliza binti Tarudin'),
      TransactionKind.promo: (300, 'RAYA2026 promotion credit applied'),
    };
    money.forEach((kind, v) {
      rides.addTransaction(kind: kind, amount: v.$1, description: v.$2);
    });

    // Bodies long enough to wrap, because that is what a notification is.
    const alerts = <(NotificationKind, String, String)>[
      (
        NotificationKind.ride,
        'Your driver is arriving',
        'Muhammad Firdaus bin Abdul Rahman is two minutes away in a Granite '
            'Grey Perodua Bezza, WXY 1234.',
      ),
      (
        NotificationKind.promo,
        'RM3 off your next five trips',
        'Use code RAYA2026 before the end of the month on any city trip paid '
            'from your wallet.',
      ),
      (
        NotificationKind.safety,
        'Share your trip with someone',
        'Your trusted contacts can follow this trip live until you arrive at '
            'Bangsar South City Park Residences.',
      ),
      (
        NotificationKind.system,
        'Weekly payout sent',
        'RM250.00 is on its way to Maybank ****4321 and should arrive within '
            'one working day.',
      ),
    ];
    for (final (kind, title, body) in alerts) {
      rides.notify(kind: kind, title: title, body: body, alert: false);
    }
    // One left unread, so the badge and the read/unread row both render.
    rides.markNotificationsRead();
    rides.notify(
      kind: NotificationKind.ride,
      title: 'A driver bid on your ride',
      body: 'RM18.50 — three minutes away. Tap to see the offer.',
      rideId: rideId,
      alert: false,
    );

    // Both sides of a conversation, and one message long enough to wrap.
    rides.sendMessage(rideId, Role.passenger, 'Hi, I am at the north entrance');
    rides.sendMessage(rideId, Role.driver, 'On my way, five minutes');
    rides.sendMessage(
      rideId,
      Role.passenger,
      'I am standing by the taxi rank next to the blue pillar, wearing a blue '
      'jacket. There are three of us and two large suitcases.',
    );
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
  ///
  /// [locale] has to be passed, not left to the ambient default. Setting
  /// `supportedLocales` alone does not pick one — the harness falls back to
  /// English — so for a long time both gates laid out all 23 screens twice
  /// and never once in Malay, which is 17% more characters across the strings
  /// the two locales share, longer in 70% of them, and more than twice as
  /// long in some of the short ones that sit in pills and buttons.
  Widget wrap(
    Widget screen, {
    double scale = 1.0,
    bool dark = true,
    Locale locale = const Locale('en'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionStore>.value(value: session),
        ChangeNotifierProvider<RidesStore>.value(value: rides),
        ChangeNotifierProvider<DraftStore>.value(value: draft),
        Provider<Notifier>.value(value: const SilentNotifier()),
      ],
      child: MaterialApp(
        theme: buildTheme(dark: dark),
        locale: locale,
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
