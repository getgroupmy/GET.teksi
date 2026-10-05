import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/state/draft.dart';

import 'support/screens.dart';
import 'support/semantics.dart';

/// The twenty sheets that only exist after a tap.
///
/// `showAppSheet` is called from twenty places and exactly one of them had
/// ever been rendered by a test — the wallet's top-up sheet, and only because
/// error_states_test.dart happened to walk into it while looking for
/// something else. The other nineteen had never been drawn.
///
/// It is the same blind spot as the mid-ride sheets in #32, which the gates
/// missed because they only exist while a ride is in a particular state.
/// These are a step further out: they exist only after somebody taps.
///
/// They are also the densest text in the app. A cancel sheet is a list of
/// reasons, each a sentence; the car chooser is three rows of name, example
/// and seat count; the SOS sheet is a paragraph with a phone number in it.
/// And a modal sheet is the one place where running out of room cannot be
/// scrolled away from, because the sheet sizes itself to its content.
void main() {
  final app = ScreenFixture();

  setUp(() async => app.reset());

  Future<String?> openAndLayout(
    WidgetTester tester, {
    required void Function(AppLocalizations) prepare,
    required Widget Function() screen,
    required Finder Function(AppLocalizations) opener,
    required double scale,
    required Locale locale,
    required String Function(AppLocalizations) title,
  }) async {
    final l = await AppLocalizations.delegate.load(locale);
    prepare(l);

    final complaints = <String>[];
    final previous = FlutterError.onError;
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
            : '${details.exception}\n    in '
                  '${creator.substring('debugCreator: '.length)}',
      );
    };
    addTearDown(() => FlutterError.onError = previous);

    app.sizeAsPhone(tester);
    await tester.pumpWidget(app.wrap(screen(), scale: scale, locale: locale));
    await tester.pump(const Duration(milliseconds: 350));

    // ensureVisible first: at double the text size the control that opens a
    // sheet is often below the fold, and a tap that lands on nothing only
    // warns — it would leave the sheet unopened and this measuring the
    // screen behind it.
    final control = opener(l);
    // A ListView only builds what is on screen, so a control below the fold
    // is not merely invisible — it does not exist to be found. Scrolling has
    // to come before the lookup, not after it.
    if (control.evaluate().isEmpty) {
      await tester.scrollUntilVisible(control, 200, maxScrolls: 30);
      await tester.pump();
    }
    expect(
      control,
      findsWidgets,
      reason: 'nothing on this screen opens the sheet',
    );
    // And once it exists it may still be off the bottom. ensureVisible is not
    // used for this: on an already-visible target it still drives the nearest
    // Scrollable, and on two of these screens that never came back — the test
    // died on a timeout naming nothing useful.
    final surface = tester.view.physicalSize / tester.view.devicePixelRatio;
    final where = tester.getRect(control.first);
    if (where.top < 0 || where.bottom > surface.height) {
      await tester.scrollUntilVisible(control.first, 120, maxScrolls: 20);
      await tester.pump();
    }
    await tester.tap(control.first);
    // A modal sheet animates in; one frame is not enough to have it.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    FlutterError.onError = previous;
    return complaints.isEmpty ? null : complaints.first;
  }

  /// Every sheet: what state it needs, where it is opened from, and the title
  /// that proves the right one opened.
  final sheets =
      <
        String,
        ({
          void Function(AppLocalizations) prepare,
          Widget Function() screen,
          Finder Function(AppLocalizations) opener,
          String Function(AppLocalizations) title,
        })
      >{};

  void sheet(
    String name, {
    void Function(AppLocalizations)? prepare,
    required String screen,
    required Finder Function(AppLocalizations) opener,
    required String Function(AppLocalizations) title,
  }) {
    sheets[name] = (
      prepare: prepare ?? (_) {},
      screen: () => app.screens()[screen]!(),
      opener: opener,
      title: title,
    );
  }

  sheet(
    'wallet top-up',
    screen: 'WalletScreen',
    opener: (l) => find.text(l.topUp),
    title: (l) => l.topUpTitle,
  );
  sheet(
    'profile edit',
    screen: 'ProfileScreen',
    opener: (l) => find.text(l.edit),
    title: (l) => l.editProfile,
  );
  sheet(
    'set home',
    screen: 'PlacesScreen',
    opener: (l) => find.text(l.addHome),
    title: (l) => l.setYourHome,
  );
  sheet(
    'set work',
    screen: 'PlacesScreen',
    opener: (l) => find.text(l.addWork),
    title: (l) => l.setYourWork,
  );
  sheet(
    'emergency SOS',
    screen: 'SafetyScreen',
    opener: (l) => find.text(l.emergencySos),
    title: (l) => l.emergencySos,
  );
  sheet(
    'report a problem',
    screen: 'SafetyScreen',
    opener: (l) => find.text(l.reportAProblem),
    title: (l) => l.reportAProblem,
  );
  sheet(
    'add emergency contact',
    screen: 'SafetyScreen',
    opener: (l) => find.text(l.add),
    title: (l) => l.addEmergencyContact,
  );
  sheet(
    'sign out',
    screen: 'MenuScreen',
    opener: (l) => find.text(l.signOut),
    title: (l) => l.signOutConfirmTitle,
  );
  sheet(
    'clear local data',
    screen: 'SettingsScreen',
    opener: (l) => find.text(l.clearLocalData),
    title: (l) => l.clearLocalDataConfirmTitle,
  );
  sheet(
    'edit vehicle',
    screen: 'VehicleScreen',
    opener: (l) => find.text(l.editDetails),
    title: (l) => l.editVehicle,
  );

  void priceSheet(
    String name,
    Finder Function(AppLocalizations) opener,
    String Function(AppLocalizations) title,
  ) {
    sheet(
      name,
      prepare: (_) {
        app.draft.setPickup(place('KLCC Tower 2 North Entrance', klcc));
        app.draft.setDropoff(
          place('Mid Valley Megamall South Court', midValley),
        );
        app.draft.setStep(DraftStep.price);
      },
      screen: 'PassengerHomeScreen',
      opener: opener,
      title: title,
    );
  }

  priceSheet(
    'choose car type',
    (l) => find.text(l.carEconomy),
    (l) => l.chooseCarType,
  );
  priceSheet(
    'payment method',
    (l) => find.text(l.cash),
    (l) => l.paymentMethod,
  );
  priceSheet(
    'note for driver',
    (l) => find.text(l.note),
    (l) => l.noteForDriver,
  );
  priceSheet('trip options', (l) => find.text(l.extras), (l) => l.tripOptions);

  void offersSheet(
    String name,
    Finder Function(AppLocalizations) opener,
    String Function(AppLocalizations) title,
  ) {
    sheet(
      name,
      prepare: (_) => app.giveLiveRide(
        as: Role.passenger,
        status: RideStatus.searching,
        withOffers: true,
      ),
      screen: 'PassengerHomeScreen',
      opener: opener,
      title: title,
    );
  }

  offersSheet(
    'raise your price',
    (l) => find.text(l.raiseYourPrice),
    (l) => l.raiseYourPrice,
  );
  offersSheet(
    'cancel your order',
    (l) => find.byTooltip(l.cancelSearch),
    (l) => l.cancelYourOrder,
  );

  void trackingSheet(
    String name,
    Finder Function(AppLocalizations) opener,
    String Function(AppLocalizations) title,
  ) {
    sheet(
      name,
      prepare: (_) =>
          app.giveLiveRide(as: Role.passenger, status: RideStatus.accepted),
      screen: 'PassengerHomeScreen',
      opener: opener,
      title: title,
    );
  }

  trackingSheet(
    'share your trip',
    (l) => find.text(l.shareLabel),
    (l) => l.shareYourTrip,
  );
  trackingSheet(
    'cancel ride',
    (l) => find.text(l.cancelRide),
    (l) => l.cancelRideTitle,
  );

  sheet(
    'cancel order, driver side',
    prepare: (_) {
      app.session.setRole(Role.driver);
      app.giveLiveRide(as: Role.driver, status: RideStatus.accepted);
    },
    screen: 'DriverHomeScreen',
    opener: (l) => find.text(l.cancelThisOrder),
    title: (l) => l.cancelOrderConfirmTitle,
  );
  sheet(
    'filter orders',
    prepare: (_) {
      app.session.setRole(Role.driver);
      app.session.setPrefs(app.session.prefs.copyWith(driverOnline: true));
    },
    screen: 'DriverHomeScreen',
    // The button's tooltip is `filters`; `filterOrders` is the
    // sheet's own title.
    opener: (l) => find.byTooltip(l.filters),
    title: (l) => l.filterOrders,
  );

  group('the tap really does open the sheet', () {
    sheets.forEach((name, s) {
      testWidgets(name, timeout: const Timeout(Duration(seconds: 40)), (
        tester,
      ) async {
        await openAndLayout(
          tester,
          prepare: s.prepare,
          screen: s.screen,
          opener: s.opener,
          scale: 1.0,
          locale: const Locale('en'),
          title: s.title,
        );
        final l = await AppLocalizations.delegate.load(const Locale('en'));
        expect(
          find.text(s.title(l)),
          findsWidgets,
          reason:
              '"$name" did not open, so everything measured for it below is '
              'the screen behind it and this would pass however badly the '
              'sheet renders.',
        );
      });
    });
  });

  for (final locale in appLocales) {
    final lang = locale.languageCode;
    for (final scale in [1.0, 2.0]) {
      group('in $lang at ${scale}x', () {
        sheets.forEach((name, s) {
          testWidgets(
            '$name lays out',
            timeout: const Timeout(Duration(seconds: 40)),
            (tester) async {
              final error = await openAndLayout(
                tester,
                prepare: s.prepare,
                screen: s.screen,
                opener: s.opener,
                scale: scale,
                locale: locale,
                title: s.title,
              );
              expect(
                error,
                isNull,
                reason:
                    '"$name" overflows in $lang at ${scale}x. A sheet sizes '
                    'itself to its content, so there is nothing to scroll '
                    'away from:\n$error',
              );
            },
          );
        });
      });
    }
  }

  group('every control on these sheets announces itself', () {
    sheets.forEach((name, s) {
      testWidgets(name, timeout: const Timeout(Duration(seconds: 40)), (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await openAndLayout(
          tester,
          prepare: s.prepare,
          screen: s.screen,
          opener: s.opener,
          scale: 1.0,
          locale: const Locale('en'),
          title: s.title,
        );
        final root = tester.getSemantics(find.byType(Scaffold).first);
        final silent = controls(root).where((n) => !announcesSomething(n));
        expect(
          silent.map(describeNode).toList(),
          isEmpty,
          reason:
              'On the "$name" sheet a screen reader would reach these and '
              'have nothing to read out.',
        );
        handle.dispose();
      });
    });
  });
}
