import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/router.dart';
import 'package:get_teksi/screens/driver/earnings_screen.dart';
import 'package:get_teksi/screens/driver/order_detail_screen.dart';
import 'package:get_teksi/screens/driver/vehicle_screen.dart';
import 'package:get_teksi/screens/shared/menu_screen.dart';
import 'package:get_teksi/screens/shared/places_screen.dart';
import 'package:get_teksi/screens/shared/profile_screen.dart';
import 'package:get_teksi/screens/shared/promos_screen.dart';
import 'package:get_teksi/theme.dart';
import 'package:provider/provider.dart';

import 'support/screens.dart';

/// Which screens each role can reach, and what entering one says about the
/// role in use.
///
/// The redirect keeps a driver on the driver home and a passenger on the
/// passenger home, which is right. It decided that by prefix — `/p` for the
/// passenger side — and `/profile`, `/places` and `/promos` all begin with
/// `/p`. So a signed-in driver who tapped Profile in the menu was sent back
/// to the driver home screen, and so were Saved places and Promotions. Four
/// entry points: three rows in MenuScreen and a button on WalletScreen.
///
/// Nothing caught it. These are not layout bugs, so the text-scale gate had
/// nothing to say; the screens are reachable in a widget test, because a
/// widget test builds them directly and never consults the router. It took
/// opening them in a browser as a driver and noticing the address bar.
void main() {
  final app = ScreenFixture();
  setUp(() async => app.reset());

  /// Pumps the real router — not a screen built directly — so the redirect
  /// actually runs. That is the whole point: every one of these screens
  /// renders perfectly well when constructed by hand.
  Future<void> openAs(WidgetTester tester, Role role, String location) async {
    app.session.setRole(role);
    final config = GoRouterConfig(app.session);
    addTearDown(config.dispose);
    config.router.go(location);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app.session),
          ChangeNotifierProvider.value(value: app.rides),
          ChangeNotifierProvider.value(value: app.draft),
          Provider<Notifier>.value(value: const SilentNotifier()),
        ],
        child: MaterialApp.router(
          theme: buildTheme(dark: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: config.router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  const shared = <String, Type>{
    '/profile': ProfileScreen,
    '/places': PlacesScreen,
    '/promos': PromosScreen,
  };

  for (final role in Role.values) {
    shared.forEach((location, screen) {
      testWidgets('a ${role.name} can open $location', (tester) async {
        await openAs(tester, role, location);
        expect(
          find.byType(screen),
          findsOneWidget,
          reason:
              'a ${role.name} asked for $location and got something else. '
              'MenuScreen links here, so this is a dead row in the menu.',
        );
      });
    });
  }

  /// The same over-match, one level down.
  ///
  /// `inSection('/d')` was standing in for "the driver home", which is what
  /// the guard's own comment says it keeps each role on. It is wider than
  /// that: it covers the driver *account* screens too. MenuScreen offers
  /// Earnings and Vehicle & documents on `user.isDriver` — whether the
  /// account has a driver profile — and not on the role being used right
  /// now, so a driver riding as a passenger saw both rows and neither
  /// opened. Tapping one sent them to the passenger home instead.
  ///
  /// Reachable from the fixture's own default state, with no setup: the user
  /// has a driver profile and the role starts as passenger. Every gate that
  /// walks the screens drew those two rows, and nothing tapped them.
  const account = <String, Type>{
    '/d/earnings': EarningsScreen,
    '/d/vehicle': VehicleScreen,
  };

  for (final role in Role.values) {
    account.forEach((location, screen) {
      testWidgets('a ${role.name} with a driver profile can open $location', (
        tester,
      ) async {
        await openAs(tester, role, location);
        expect(
          find.byType(screen),
          findsOneWidget,
          reason:
              'a ${role.name} asked for $location and got something else. '
              'MenuScreen shows this row to anyone whose account has a '
              'driver profile, so this is a dead row in the menu.',
        );
      });
    });
  }

  // Through the menu, the way a person reaches them. Opening the location
  // directly proves the guard allows it; tapping proves the row leads there,
  // which is the part that was broken.
  for (final (label, screen) in [
    ('earnings', EarningsScreen),
    ('vehicleAndDocuments', VehicleScreen),
  ]) {
    testWidgets('a passenger tapping $label in the menu opens it', (
      tester,
    ) async {
      await openAs(tester, Role.passenger, '/menu');
      expect(find.byType(MenuScreen), findsOneWidget);

      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final row = find.text(
        label == 'earnings' ? l.earnings : l.vehicleAndDocuments,
      );
      expect(
        row,
        findsOneWidget,
        reason:
            'the row is shown on user.isDriver, so a passenger-role driver '
            'sees it. If it has stopped being shown, the tap below proves '
            'nothing about the guard.',
      );
      await tester.tap(row);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.byType(screen),
        findsOneWidget,
        reason:
            'tapping $label moved the passenger somewhere else instead of '
            'opening it — the row did nothing but navigate away.',
      );
    });
  }

  /// What replaced the refusal.
  ///
  /// A role's half of the app used to be refused to the other role, and that
  /// refusal was the only thing making the browser's Back button useless —
  /// see `test/browser_history_test.dart`. It protected nothing: switching
  /// role is a button on both home screens and a third in the menu, so both
  /// halves were already one tap apart. Entering a half now says which role
  /// is in use, and `prefs.role` follows.
  ///
  /// It has to follow, not merely stop being enforced: `isDriverOnDuty` reads
  /// it, and the position beacon and the foreground service both agree on
  /// that. A role pointing at the half you are not in would stop a driver
  /// going on duty.
  for (final (from, to, location) in [
    (Role.passenger, Role.driver, '/d'),
    (Role.driver, Role.passenger, '/p'),
  ]) {
    testWidgets('opening $location as a ${from.name} makes them a ${to.name}', (
      tester,
    ) async {
      await openAs(tester, from, location);
      expect(
        app.session.prefs.role,
        to,
        reason:
            'the role did not follow the location. isDriverOnDuty reads it, '
            'so a role left pointing at the other half stops the duty '
            'beacon from ever starting.',
      );
    });
  }

  testWidgets('and a driver order is driver work, so it switches too', (
    tester,
  ) async {
    await openAs(tester, Role.passenger, '/d/order/${app.rideId}');
    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(app.session.prefs.role, Role.driver);
  });

  // The account screens are the exception, and this is what names them. They
  // are offered to anyone whose account has a driver profile, so opening one
  // must not quietly put a passenger behind the wheel.
  for (final location in ['/d/earnings', '/d/vehicle', '/d/onboarding']) {
    testWidgets('opening $location leaves a passenger a passenger', (
      tester,
    ) async {
      await openAs(tester, Role.passenger, location);
      expect(
        app.session.prefs.role,
        Role.passenger,
        reason:
            '$location belongs to the driver account, not to driving. '
            'Reading the whole /d section as the driver half would switch '
            'a passenger here.',
      );
    });
  }

  // Only a profile makes somebody a driver, and the role must not be handed
  // out by a URL. Without this, typing /d would set role: driver on an
  // account with no vehicle on file, and isDriverOnDuty would be one
  // `driverOnline` away from true for somebody who cannot drive.
  testWidgets('an account with no driver profile is not made a driver', (
    tester,
  ) async {
    app.session.signOut();
    app.session.signIn('+60123456789', name: 'Nurul Ain binti Abdullah');
    expect(app.session.requireUser.isDriver, isFalse);

    await openAs(tester, Role.passenger, '/d');
    expect(
      app.session.prefs.role,
      Role.passenger,
      reason: 'a URL cannot make somebody a driver; becomeDriver does',
    );
  });
}
