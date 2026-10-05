import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/router.dart';
import 'package:get_teksi/screens/driver/order_detail_screen.dart';
import 'package:get_teksi/screens/passenger/destination_search_screen.dart';
import 'package:get_teksi/screens/shared/rate_screen.dart';
import 'package:get_teksi/theme.dart';
import 'package:get_teksi/widgets/ui.dart';
import 'package:provider/provider.dart';

import 'support/screens.dart';

/// A ride, screen to screen, through the router the app actually uses.
///
/// Two test files drive `GoRouterConfig`, and both ask the same single
/// question: open one location, see what rendered. Nothing had ever navigated
/// *from* one screen *to* the next. Every multi-screen journey in the app —
/// which is to say the app — was unexercised as a journey.
///
/// The gap is the same one that hid the redirect bug fixed in #25: a widget
/// test builds a screen directly and never consults the router, so a guard
/// that sends you somewhere else is invisible to it. That is now covered for
/// a single route. The transitions between them were not.
///
/// It also lays those states out, without meaning to and worth saying: an
/// overflow is an uncaught FlutterError, and an uncaught FlutterError fails
/// the test it happens in. That is how the price sheet's class row was found
/// — a `spaceBetween` Row with neither child flexible, holding the distance
/// on one side and "Everyday cars, 4 seats" on the other ("Kereta harian, 4
/// tempat duduk" in Malay). text_scale_test walks PassengerHomeScreen twice
/// in each locale and never saw it, because the sheet only appears once a
/// draft has both ends, and a fixture does not take a journey.
///
/// What this is not: a test of the marketplace. Whether a bot bids, and when,
/// belongs to marketplace_test.dart and is driven here through the store so
/// the subject stays navigation. The question each step asks is only ever
/// "the screen did this, where did the router put me".
void main() {
  final app = ScreenFixture();
  late GoRouterConfig config;

  setUp(() async => app.reset());

  /// The location the router believes it is at, which is the thing under
  /// test. Reading the rendered screen instead would miss a redirect that
  /// lands somewhere that happens to look similar.
  /// The route on top of the stack.
  ///
  /// `currentConfiguration.uri` is the location the stack was *built from*,
  /// not where it ends: after pushing /d/order/x onto /d it still reads /d,
  /// with the pushed route only in `matches`. A check written against it
  /// would go on passing while asserting that a push left you where you
  /// were — which is the one thing this file exists to notice.
  String here() => config
      .router
      .routerDelegate
      .currentConfiguration
      .matches
      .last
      .matchedLocation;

  Future<void> start(WidgetTester tester, Role role, String at) async {
    app.session.setRole(role);
    config = GoRouterConfig(app.session);
    addTearDown(config.dispose);
    config.router.go(at);

    app.sizeAsPhone(tester);
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

  Future<void> settle(WidgetTester tester) async {
    // Not pumpAndSettle: the map and the countdown never stop, so it would
    // time out rather than settle.
    //
    // Four frames, because a push from a post-frame callback needs them: the
    // store notifies, the screen rebuilds and registers the callback, the
    // callback runs and the router's configuration changes, and only then is
    // the new screen built. `currentConfiguration` moves on the push, so a
    // check of the location alone passes a frame before the screen exists.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 350));
    }
  }

  group('the passenger journey', () {
    testWidgets('home to destination search and back', (tester) async {
      await start(tester, Role.passenger, '/p');
      expect(here(), '/p');

      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l.whereTo));
      await settle(tester);
      expect(
        here(),
        '/p/search',
        reason: 'tapping Where to? on the idle sheet pushes the search route',
      );
      expect(find.byType(DestinationSearchScreen), findsOneWidget);

      // Picking a destination pops back only once both ends are known —
      // _choose() returns without popping while the pickup is still empty,
      // and switches to editing that instead. In the app the pickup comes
      // from location services, which a widget test has none of, so it is
      // set here rather than tapped.
      app.draft.setPickup(place('KLCC Tower 2', klcc));
      await settle(tester);
      await tester.tap(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await settle(tester);
      expect(
        here(),
        '/p',
        reason: 'choosing a destination with a pickup already set pops home',
      );
    });

    testWidgets('a finished ride leads to rating, and rating leads home', (
      tester,
    ) async {
      await start(tester, Role.passenger, '/p');

      // The ride itself is set up through the store: whether a bot bids is
      // marketplace_test.dart's question, not this file's.
      final user = app.session.requireUser;
      final ride = app.rides.publishRide(
        buildFinishedRide(
          userId: user.id,
          asDriver: false,
          status: RideStatus.completed,
          // The fixture rates both sides by default, precisely so the other
          // gates — which have no router — are not sent to /rate and made to
          // throw. Here the push is the subject.
          rated: false,
        ),
      );
      await settle(tester);

      expect(
        here(),
        '/rate/${ride.id}',
        reason:
            'PassengerHomeScreen pushes the rating screen from a post-frame '
            'callback when a ride is awaiting one. That push happens during '
            'a frame, which is exactly where a route that is not ready '
            'throws "No GoRouter found in context".',
      );
      expect(find.byType(RateScreen), findsOneWidget);

      // Submit stays disabled until a star is picked — `onPressed` is null
      // while _stars == 0 — so tapping it first does nothing at all and the
      // journey quietly stops here.
      await tester.tap(find.byType(IconButton).at(4));
      await settle(tester);
      await tester.tap(find.byType(FilledButton).last);
      await settle(tester);
      expect(
        here(),
        '/p',
        reason: 'RateScreen sends a passenger back to the passenger home',
      );
    });
  });

  group('the driver journey', () {
    testWidgets('home to an order and back', (tester) async {
      await start(tester, Role.driver, '/d');
      expect(here(), '/d');

      final open = app.rides.rides.values.firstWhere(
        (r) => r.status == RideStatus.searching,
      );
      config.router.push('/d/order/${open.id}');
      await settle(tester);
      expect(here(), '/d/order/${open.id}');
      expect(find.byType(OrderDetailScreen), findsOneWidget);

      // The back button is the way out of an order, and it has to land on
      // the driver home rather than wherever the stack happened to be.
      await tester.tap(find.byType(AppBackButton).first);
      await settle(tester);
      expect(here(), '/d');
    });

    testWidgets('rating sends a driver to the driver home', (tester) async {
      await start(tester, Role.driver, '/d');

      final user = app.session.requireUser;
      final ride = app.rides.publishRide(
        buildFinishedRide(
          userId: user.id,
          asDriver: true,
          status: RideStatus.completed,
          rated: false,
        ),
      );
      await settle(tester);
      expect(here(), '/rate/${ride.id}');

      // Submit stays disabled until a star is picked — `onPressed` is null
      // while _stars == 0 — so tapping it first does nothing at all and the
      // journey quietly stops here.
      await tester.tap(find.byType(IconButton).at(4));
      await settle(tester);
      await tester.tap(find.byType(FilledButton).last);
      await settle(tester);
      expect(
        here(),
        '/d',
        reason:
            'RateScreen branches on the viewer role. A driver sent to /p '
            'would be bounced back by the role guard, which looks like it '
            'works and is a redirect away from where the screen meant.',
      );
    });
  });

  group('the gate itself', () {
    testWidgets('here reports the router, not the screen', (tester) async {
      // A passenger asking for the driver home is redirected. If `here` read
      // the rendered widget it would say /d and this would pass wrongly.
      await start(tester, Role.passenger, '/d');
      expect(here(), '/p');
    });
  });
}
