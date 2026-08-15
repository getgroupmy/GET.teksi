import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'screens/auth/intro_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/phone_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/earnings_screen.dart';
import 'screens/driver/onboarding_screen.dart';
import 'screens/driver/order_detail_screen.dart';
import 'screens/driver/vehicle_screen.dart';
import 'screens/passenger/destination_search_screen.dart';
import 'screens/passenger/passenger_home_screen.dart';
import 'screens/shared/chat_screen.dart';
import 'screens/shared/history_screen.dart';
import 'screens/shared/menu_screen.dart';
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/places_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/promos_screen.dart';
import 'screens/shared/rate_screen.dart';
import 'screens/shared/ride_detail_screen.dart';
import 'screens/shared/safety_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'screens/shared/wallet_screen.dart';
import 'state/session.dart';

/// Routing, including the auth and role guards.
class GoRouterConfig {
  GoRouterConfig(this._session) {
    _session.addListener(_notifier.bump);
    router = GoRouter(
      initialLocation: '/p',
      refreshListenable: _notifier,
      redirect: _redirect,
      routes: [
        GoRoute(path: '/intro', builder: (_, _) => const IntroScreen()),
        GoRoute(path: '/auth/phone', builder: (_, _) => const PhoneScreen()),
        GoRoute(
          path: '/auth/otp',
          builder: (_, state) => OtpScreen(phone: state.extra as String? ?? ''),
        ),
        GoRoute(
          path: '/auth/profile',
          builder: (_, state) =>
              ProfileSetupScreen(phone: state.extra as String? ?? ''),
        ),

        GoRoute(path: '/p', builder: (_, _) => const PassengerHomeScreen()),
        GoRoute(
          path: '/p/search',
          builder: (_, _) => const DestinationSearchScreen(),
        ),

        GoRoute(path: '/d', builder: (_, _) => const DriverHomeScreen()),
        GoRoute(
          path: '/d/onboarding',
          builder: (_, _) => const DriverOnboardingScreen(),
        ),
        GoRoute(path: '/d/earnings', builder: (_, _) => const EarningsScreen()),
        GoRoute(path: '/d/vehicle', builder: (_, _) => const VehicleScreen()),
        GoRoute(
          path: '/d/order/:rideId',
          builder: (_, state) =>
              OrderDetailScreen(rideId: state.pathParameters['rideId']!),
        ),

        GoRoute(
          path: '/chat/:rideId',
          builder: (_, state) =>
              ChatScreen(rideId: state.pathParameters['rideId']!),
        ),
        GoRoute(
          path: '/rate/:rideId',
          builder: (_, state) =>
              RateScreen(rideId: state.pathParameters['rideId']!),
        ),
        GoRoute(
          path: '/ride/:rideId',
          builder: (_, state) =>
              RideDetailScreen(rideId: state.pathParameters['rideId']!),
        ),

        GoRoute(path: '/menu', builder: (_, _) => const MenuScreen()),
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/safety',
          builder: (_, state) => SafetyScreen(rideId: state.extra as String?),
        ),
        GoRoute(path: '/promos', builder: (_, _) => const PromosScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(path: '/places', builder: (_, _) => const PlacesScreen()),
      ],
    );
  }

  final SessionStore _session;
  final _RouterNotifier _notifier = _RouterNotifier();
  late final GoRouter router;

  void dispose() {
    _session.removeListener(_notifier.bump);
    _notifier.dispose();
    router.dispose();
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;
    final signedIn = _session.user != null;
    final onAuthRoute = path.startsWith('/auth') || path == '/intro';

    if (!signedIn) {
      if (onAuthRoute) return null;
      return _session.prefs.hasSeenIntro ? '/auth/phone' : '/intro';
    }

    // Signed in: the auth flow is behind us.
    if (onAuthRoute) return _session.prefs.role == Role.driver ? '/d' : '/p';

    // Keep each role on its own home screen. Driver onboarding is exempt —
    // a passenger must be able to open it to become a driver at all.
    final isDriverRoute = path.startsWith('/d') && path != '/d/onboarding';
    final isPassengerRoute = path.startsWith('/p');
    if (_session.prefs.role == Role.driver && isPassengerRoute) return '/d';
    if (_session.prefs.role == Role.passenger && isDriverRoute) return '/p';

    return null;
  }
}

/// go_router rebuilds its redirect when this fires.
class _RouterNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}
