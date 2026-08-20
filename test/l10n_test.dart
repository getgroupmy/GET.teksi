import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/l10n/app_localizations.dart';

/// The Language setting is only worth having if it changes something. These
/// pin the mechanism rather than the wording: that both locales load, that
/// Malay is a translation and not a copy of the template, and that a
/// translated string still carries the values interpolated into it.

void main() {
  late AppLocalizations en;
  late AppLocalizations ms;

  setUp(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ms = await AppLocalizations.delegate.load(const Locale('ms'));
  });

  test('both locales are offered', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(<String>['en', 'ms']),
    );
  });

  test('Malay is translated, not a copy of the English template', () {
    // A handful of load-bearing strings from different screens. If the ARB
    // were ever regenerated from the template by mistake, these collapse.
    expect(ms.settings, isNot(en.settings));
    expect(ms.phoneTitle, isNot(en.phoneTitle));
    expect(ms.otpTitle, isNot(en.otpTitle));
    expect(ms.onboardTitle1, isNot(en.onboardTitle1));
    expect(ms.profileStart, isNot(en.profileStart));
  });

  test('each language names itself in its own language', () {
    // What a language picker should show: you have to be able to read the
    // option you are looking for while the app is in a language you cannot.
    expect(en.languageName, 'English');
    expect(ms.languageName, 'Bahasa Melayu');
  });

  test('placeholders survive translation', () {
    // The classic localisation bug: a translator rewrites the sentence and
    // drops the interpolation, so the user is told "Sent to " and nothing.
    expect(ms.otpSentTo('+60 12-345 6789'), contains('+60 12-345 6789'));
    expect(ms.otpResendIn(30), contains('30'));
    expect(en.otpSentTo('+60 12-345 6789'), contains('+60 12-345 6789'));
    expect(en.otpResendIn(30), contains('30'));
  });

  test('no translated string is left empty', () {
    // An empty value renders as a blank label rather than falling back, so it
    // is worse than leaving the key untranslated.
    for (final value in <String>[
      ms.settings,
      ms.language,
      ms.languageName,
      ms.appearance,
      ms.darkTheme,
      ms.preferences,
      ms.sounds,
      ms.on,
      ms.off,
      ms.demo,
      ms.simulatedMarketplace,
      ms.clearLocalData,
      ms.about,
      ms.version,
      ms.termsOfService,
      ms.privacyPolicy,
      ms.phoneTitle,
      ms.phoneSubtitle,
      ms.phoneTerms,
      ms.continueLabel,
      ms.otpTitle,
      ms.otpResend,
      ms.otpVerify,
      ms.profileTitle,
      ms.profileFullName,
      ms.profileEmail,
      ms.profileStart,
      ms.skip,
      ms.next,
      ms.getStarted,
    ]) {
      expect(value.trim(), isNotEmpty);
    }
  });
}
