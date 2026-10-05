import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/core/storage.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/router.dart';
import 'package:get_teksi/screens/auth/otp_screen.dart';
import 'package:get_teksi/screens/auth/phone_screen.dart';
import 'package:get_teksi/screens/auth/profile_setup_screen.dart';
import 'package:get_teksi/state/draft.dart';
import 'package:get_teksi/state/rides.dart';
import 'package:get_teksi/state/session.dart';
import 'package:get_teksi/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two auth steps that need a phone number they do not have in the path.
///
/// `/auth/otp` and `/auth/profile` take the number in `extra`, which the step
/// before them passes. On a phone that is the only way in. On the web every
/// route is addressable and `extra` does not survive a page load, so a reload
/// on the OTP screen — the screen people are most likely to reload, because
/// they are waiting for a message — arrived with nothing.
///
/// Both screens rendered anyway. OTP showed "Sent to +60" with no digits and
/// would have called `verifyOtp('', code)`. Profile setup was worse: its
/// submit button only checks the name, so typing one and tapping Start riding
/// called `signIn('')` and minted an account whose phone number — the identity
/// every other part of the app keys off — was the empty string.
void main() {
  late SessionStore session;
  late RidesStore rides;
  late DraftStore draft;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    // Signed out on purpose: this is the one gate whose subject is the
    // signed-out half of the redirect, and signing in skips all of it.
    session = SessionStore();
    rides = RidesStore(session);
    draft = DraftStore();
  });

  /// Pumps the real router, because the redirect is the thing under test.
  Future<void> open(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    final config = GoRouterConfig(session);
    addTearDown(config.dispose);
    config.router.go(location, extra: extra);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider.value(value: rides),
          ChangeNotifierProvider.value(value: draft),
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

  group('a deep link with no number goes back to the phone step', () {
    testWidgets('/auth/otp', (tester) async {
      await open(tester, '/auth/otp');
      expect(
        find.byType(PhoneScreen),
        findsOneWidget,
        reason:
            'a reload on the OTP screen arrives with no number. Showing the '
            'OTP screen means "Sent to +60" and a Verify that submits an '
            'empty phone.',
      );
      expect(find.byType(OtpScreen), findsNothing);
    });

    testWidgets('/auth/profile', (tester) async {
      await open(tester, '/auth/profile');
      expect(
        find.byType(PhoneScreen),
        findsOneWidget,
        reason:
            'profile setup only validates the name, so reaching it without a '
            'number signs the account in under an empty phone.',
      );
      expect(find.byType(ProfileSetupScreen), findsNothing);
    });

    testWidgets('/auth/otp with a blank string is still no number', (
      tester,
    ) async {
      await open(tester, '/auth/otp', extra: '   ');
      expect(find.byType(PhoneScreen), findsOneWidget);
    });
  });

  group('the real flow still reaches the step it pushed', () {
    testWidgets('/auth/otp carrying the number', (tester) async {
      await open(tester, '/auth/otp', extra: '+60123456789');
      expect(
        find.byType(OtpScreen),
        findsOneWidget,
        reason:
            'PhoneScreen pushes here with the number. A guard that also '
            'blocked this would have broken signing in altogether.',
      );
    });

    testWidgets('/auth/profile carrying number and auth id', (tester) async {
      await open(tester, '/auth/profile', extra: ('+60123456789', 'auth-1'));
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
    });

    testWidgets('/auth/profile carrying the number alone', (tester) async {
      // OtpScreen pushes this shape when there is no backend to mint an id.
      await open(tester, '/auth/profile', extra: '+60123456789');
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
    });
  });

  // The router guard is what a user meets. This is the invariant underneath
  // it: whatever route anyone adds later, an account without a phone number
  // is not a thing this app can hold.
  test('signing in without a number is rejected', () {
    expect(
      () => session.signIn('', name: 'Aisyah'),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => session.signIn('   ', name: 'Aisyah'),
      throwsA(isA<AssertionError>()),
    );
    expect(session.user, isNull);
  });
}
