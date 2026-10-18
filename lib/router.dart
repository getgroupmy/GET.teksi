import 'dart:async';

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
      onEnter: _onEnter,
      routes: [
        GoRoute(path: '/intro', builder: (_, _) => const IntroScreen()),
        GoRoute(path: '/auth/phone', builder: (_, _) => const PhoneScreen()),
        GoRoute(
          path: '/auth/otp',
          builder: (_, state) => switch (_authStep(state.extra)) {
            final step? => OtpScreen(phone: step.phone),
            // Unreachable: _redirect sends a missing number back to the
            // phone step before anything is built. Showing that step rather
            // than an OTP screen with no number keeps the two in agreement
            // if it ever stops being unreachable.
            _ => const PhoneScreen(),
          },
        ),
        GoRoute(
          path: '/auth/profile',
          // The verified identity travels with the route. With a backend the
          // profile has to be created under the authenticated account's id,
          // so the OTP screen passes it alongside the number; without one it
          // sends the number alone and the id is minted locally.
          builder: (_, state) => switch (_authStep(state.extra)) {
            final step? => ProfileSetupScreen(
              phone: step.phone,
              authId: step.authId,
            ),
            _ => const PhoneScreen(),
          },
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
      if (onAuthRoute) return _authStepRedirect(path, state.extra);
      return _session.prefs.hasSeenIntro ? '/auth/phone' : '/intro';
    }

    // Signed in: the auth flow is behind us.
    if (onAuthRoute) return _session.prefs.role == Role.driver ? '/d' : '/p';

    // A role's half of the app is no longer refused to the other role. The
    // role follows the location instead — see _onEnter — because refusing
    // was what made the browser's Back button a trap.
    return null;
  }

  /// Entering a role's half of the app is a statement about which role is in
  /// use, so the preference follows the location rather than refusing it.
  ///
  /// It used to refuse: a driver asking for `/p` was sent to `/d`, and a
  /// passenger asking for `/d` to `/p`. That reads as safe and was the one
  /// thing making the browser's Back button useless. On the web a location
  /// change is a history entry and go_router reports `replace: false` for
  /// all but the first, so a redirect writes history exactly like a tap. A
  /// refused location behind you is then a trap: Back spends its entry, the
  /// guard redirects, and the redirect pushes a new entry in its place. The
  /// stack ends as deep as it began, so the next press does the same. After
  /// switching role, Back never left the page — measured to fifty presses.
  ///
  /// Nothing was being protected. Switching role is a button on both home
  /// screens and a third in the menu, so both halves were already one tap
  /// apart for anybody with a driver profile; the guard only governed whoever
  /// arrived by URL or by history. `prefs.role` is now what it reads as — a
  /// preference for which half you are in — rather than a permission.
  ///
  /// It has to be kept in step rather than merely stopped being enforced:
  /// `SessionStore.isDriverOnDuty` reads it, and that is what the position
  /// beacon and the foreground service agree on. A role left pointing at the
  /// half you are not in would stop a driver going on duty.
  ///
  /// `Allow.then` runs after the navigation commits. Setting the role fires
  /// `refreshListenable`, which re-parses — and the second pass finds the
  /// role already matching and allows without a callback, so it ends there.
  FutureOr<OnEnterResult> _onEnter(
    BuildContext context,
    GoRouterState current,
    GoRouterState next,
    GoRouter router,
  ) {
    final role = _roleOwning(next.matchedLocation);
    if (role == null || _session.prefs.role == role) return const Allow();
    // Only a profile makes somebody a driver. Without one the role stays put
    // and DriverHomeScreen sends them to onboarding, which is what it already
    // did for this state.
    if (role == Role.driver && _session.user?.isDriver != true) {
      return const Allow();
    }
    return Allow(then: () => _session.setRole(role));
  }

  /// Which role's half of the app a location is in, or null for the parts
  /// that belong to neither.
  ///
  /// By section, not by prefix. `startsWith('/p')` also matches /profile,
  /// /places and /promos, so a signed-in driver who tapped Profile in the
  /// menu was redirected to the driver home — along with Saved places and
  /// Promotions, and the Promotions button on the wallet. A section is the
  /// route itself or something under it: '/p' and '/p/search', never
  /// '/profile'.
  static Role? _roleOwning(String path) {
    bool inSection(String section) =>
        path == section || path.startsWith('$section/');

    if (inSection('/p')) return Role.passenger;
    if (inSection('/d') && !_accountRoutes.contains(path)) return Role.driver;
    return null;
  }

  /// The `/d` routes that belong to the driver *account* rather than to the
  /// driver half of the app, so opening one says nothing about which role is
  /// in use.
  ///
  /// The menu offers Earnings and Vehicle & documents on `user.isDriver`, the
  /// account's driver profile, and not on the role being used right now. So a
  /// driver riding as a passenger sees both rows, and reading the whole `/d`
  /// section as the driver's half would have tapping one switch them to
  /// driving — or, while the section was refused outright, send them to the
  /// passenger home, which is what it did until this was named.
  ///
  /// Onboarding is here for its own reason: a passenger has to be able to
  /// open it to become a driver at all, and opening it does not make them
  /// one. `becomeDriver` does, when the form is submitted.
  static const _accountRoutes = {'/d/onboarding', '/d/earnings', '/d/vehicle'};

  /// Back to the step that produces the number, when a route that needs one
  /// was reached without it.
  ///
  /// `/auth/otp` and `/auth/profile` take the number in `extra` rather than
  /// in the path, because a phone number does not belong in a URL. On a
  /// phone that is enough: the only way in is the step before. On the web
  /// every route is addressable and `extra` does not survive a page load, so
  /// a reload on the OTP screen — the screen people reload most, because
  /// they are waiting for a message — arrived with nothing, and both screens
  /// rendered anyway. OTP read "Sent to +60"; profile setup, whose submit
  /// button only checks the name, signed the account in under an empty
  /// phone number.
  static String? _authStepRedirect(String path, Object? extra) {
    const needsNumber = {'/auth/otp', '/auth/profile'};
    if (!needsNumber.contains(path)) return null;
    return _authStep(extra) == null ? '/auth/phone' : null;
  }
}

/// The identity an auth step carries in `extra`, or null when it is not
/// there. The guard and the two builders read it through this one function,
/// so they cannot disagree about what counts as having a number.
({String phone, String? authId})? _authStep(Object? extra) => switch (extra) {
  (final String phone, final String? authId) when phone.trim().isNotEmpty => (
    phone: phone,
    authId: authId,
  ),
  final String phone when phone.trim().isNotEmpty => (
    phone: phone,
    authId: null,
  ),
  _ => null,
};

/// go_router rebuilds its redirect when this fires.
class _RouterNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}
