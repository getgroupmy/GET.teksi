import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/router.dart';
import 'package:get_teksi/screens/shared/places_screen.dart';
import 'package:get_teksi/screens/shared/profile_screen.dart';
import 'package:get_teksi/screens/shared/promos_screen.dart';
import 'package:get_teksi/theme.dart';
import 'package:provider/provider.dart';

import 'support/screens.dart';

/// Which screens each role is allowed to reach.
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

  // And the guard it is there for still works: the roles stay apart.
  testWidgets('a passenger is still kept off the driver home', (tester) async {
    await openAs(tester, Role.passenger, '/d');
    expect(find.byType(PlacesScreen), findsNothing);
    expect(app.session.prefs.role, Role.passenger);
  });
}
