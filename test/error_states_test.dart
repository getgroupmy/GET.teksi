import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/backend.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/screens/auth/otp_screen.dart';
import 'package:get_teksi/screens/auth/phone_screen.dart';
import 'package:get_teksi/screens/shared/chat_screen.dart';
import 'package:get_teksi/screens/shared/wallet_screen.dart';

import 'support/screens.dart';

/// The screens as they look when something has gone wrong.
///
/// There are failure strings in the ARB that nothing had ever drawn. Every one
/// of them is behind a guard of this shape:
///
///     if (!Backend.isLive) { …demo path…; return; }
///
/// `Backend._client` is null in a test and in the demo web build, so that
/// early return is always taken: the error branches are unreachable from the
/// widget gates and from the browser sweep alike. They were never laid out at
/// double the text size, never laid out in Malay, and never walked for what a
/// screen reader is given — while `test/text_scale_test.dart` and
/// `test/semantics_test.dart` both reported covering every screen, because
/// they covered the half of each screen that works.
///
/// This is the same point `_populate()` in support/screens.dart already makes
/// about empty lists: a screen that lays out cleanly with nothing in it proves
/// very little. An error banner is a line of text added to a column that was
/// already full, carrying some of the longest strings in the file.
///
/// `Backend.debugUnreachable` is what opens the door — see its comment. The
/// two states that need no backend at all (a wrong code, a ride that is gone)
/// are driven directly.
void main() {
  final app = ScreenFixture();

  setUp(() async {
    await app.reset();
    Backend.debugUnreachable = false;
  });
  tearDown(() => Backend.debugUnreachable = false);

  /// Lays [screen] out, runs [act], and returns every overflow complaint the
  /// frames after it produced.
  ///
  /// Collected through `FlutterError.onError`, like text_scale_test does, and
  /// for the same reason: `takeException` hands back the message without the
  /// `debugCreator` ancestry that names the row.
  Future<List<String>> complaintsAfter(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    required Locale locale,
    required Future<void> Function(WidgetTester tester) act,
  }) async {
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
    await tester.pumpWidget(app.wrap(screen, scale: scale, locale: locale));
    await tester.pump(const Duration(milliseconds: 350));
    await act(tester);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    // Before the caller's expects, not in a tearDown after them: an override
    // left in place while expect() runs makes the binding assert that a test
    // "overrode FlutterError.onError but failed to return it".
    FlutterError.onError = previous;
    return complaints;
  }

  /// Taps something that may have been pushed below the fold.
  ///
  /// At double the text size the phone screen's button is at y=919 in an 852
  /// pixel viewport — by design, the column scrolls past that point and the
  /// comment in phone_screen.dart says so. A plain tap() there lands on
  /// nothing and warns rather than failing, which would have left the error
  /// state unreached and the test measuring the ordinary screen.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  /// One error state: how to reach it, and the string that proves it arrived.
  ///
  /// The proof is the point. An interaction that quietly stopped working would
  /// leave a test laying out the ordinary screen and reporting it clean, which
  /// is exactly the kind of green this is meant to replace.
  final states =
      <
        String,
        ({
          bool unreachable,
          Widget Function() screen,
          Future<void> Function(WidgetTester, AppLocalizations) act,
          String Function(AppLocalizations) proof,
        })
      >{
        'PhoneScreen cannot send a code': (
          unreachable: true,
          screen: () => const PhoneScreen(),
          act: (tester, l) async {
            await tester.enterText(find.byType(TextField).first, '123456789');
            await tester.pump();
            await tapVisible(tester, find.byType(FilledButton).last);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
          },
          proof: (l) => l.phoneSendFailed,
        ),
        'OtpScreen rejects the code': (
          unreachable: true,
          screen: () => const OtpScreen(phone: '+60123456789'),
          act: (tester, l) async {
            await tester.enterText(find.byType(EditableText).first, '000000');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
          },
          proof: (l) => l.otpWrongOrExpired,
        ),
        'OtpScreen cannot resend': (
          unreachable: true,
          screen: () => const OtpScreen(phone: '+60123456789'),
          act: (tester, l) async {
            // Behind a 30 second countdown driven by a periodic timer, so
            // the clock advances a tick at a time rather than in one jump.
            //
            // By the exact string, not a pattern: "Resend code" and "Resend
            // code in 25s" both contain "resend", and in Malay "Hantar
            // semula kod" and "Hantar semula kod dalam 25s" both contain
            // "hantar". Matching loosely found the countdown, which is not a
            // button, and the test sat there until the ten minute timeout.
            for (var i = 0; i < 31; i++) {
              await tester.pump(const Duration(seconds: 1));
            }
            await tapVisible(tester, find.text(l.otpResend));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
          },
          proof: (l) => l.otpResendFailed,
        ),
        'OtpScreen on a wrong code': (
          unreachable: false,
          screen: () => const OtpScreen(phone: '+60123456789'),
          act: (tester, l) async {
            // Demo build, so the expected code is known and this is not it.
            await tester.enterText(find.byType(EditableText).first, '111111');
            await tester.pump();
          },
          proof: (l) => l.otpMismatch,
        ),
        'ChatScreen for a ride that is gone': (
          unreachable: false,
          screen: () => const ChatScreen(rideId: 'no-such-ride'),
          act: (tester, l) async {},
          proof: (l) => l.chatUnavailableBody,
        ),
        'WalletScreen cannot top up': (
          // Behind `if (Backend.isLive)` as well: with no backend the button
          // does something else entirely, so the sheet never opens.
          unreachable: true,
          screen: () => const WalletScreen(),
          act: (tester, l) async {
            await tapVisible(tester, find.text(l.topUp));
            // A modal sheet animates in; one frame is not enough to have it.
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump(const Duration(milliseconds: 400));
          },
          proof: (l) => l.topUpUnavailable,
        ),
      };

  for (final entry in states.entries) {
    for (final locale in appLocales) {
      for (final scale in [1.0, 2.0]) {
        final where = 'in ${locale.languageCode} at ${scale}x';
        testWidgets('${entry.key} $where', (tester) async {
          Backend.debugUnreachable = entry.value.unreachable;
          final l = await AppLocalizations.delegate.load(locale);
          final complaints = await complaintsAfter(
            tester,
            entry.value.screen(),
            scale: scale,
            locale: locale,
            act: (tester) => entry.value.act(tester, l),
          );

          // Did the state actually arrive? If not, everything below is a
          // measurement of the ordinary screen.
          expect(
            find.textContaining(entry.value.proof(l)),
            findsWidgets,
            reason:
                '${entry.key} did not reach its error state $where, so this '
                'laid out the screen working and would pass however badly '
                'the error state renders. Expected to find '
                '"${entry.value.proof(l)}".',
          );

          expect(
            complaints,
            isEmpty,
            reason:
                '${entry.key} overflows $where. The words are not clipped '
                'politely — a RenderFlex that does not fit paints a striped '
                'bar in debug and silently drops the text in release, and '
                'the text here is the only thing telling the user what went '
                'wrong:\n${complaints.join('\n\n')}',
          );
        });
      }
    }
  }

  group('the gate itself', () {
    testWidgets('the proof catches a state that never arrived', (tester) async {
      // No failure forced, so the demo path is taken and the error never
      // appears. The proof must notice.
      Backend.debugUnreachable = false;
      await complaintsAfter(
        tester,
        const PhoneScreen(),
        scale: 1.0,
        locale: const Locale('en'),
        act: (tester) async {
          await tester.enterText(find.byType(TextField).first, '123456789');
          await tester.pump();
        },
      );
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.textContaining(l.phoneSendFailed), findsNothing);
    });

    testWidgets('the seam is what reaches the error branch', (tester) async {
      expect(Backend.isLive, isFalse);
      Backend.debugUnreachable = true;
      expect(Backend.isLive, isTrue);
      // Synchronously: the `client` getter throws when sendOtp is called, so
      // there is no future to await. phone_screen.dart catches it either way
      // because the call is inside the try.
      expect(() => Backend.sendOtp('+60123456789'), throwsA(isA<StateError>()));
    });
  });
}
