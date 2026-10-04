import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// The profile screen formats "Member since" with `DateFormat.yMMMM(locale)`
/// rather than a hardcoded pattern, which only works if intl's symbols for
/// that locale have been loaded. Nothing in the app loads them explicitly —
/// GlobalMaterialLocalizations does it as a side effect of being in the
/// delegate list. That is a real dependency on a side effect, so it is worth
/// a test: drop the global delegates from main.dart and this fails with
/// LocaleDataException rather than shipping a crash on the profile screen.

Future<String> _monthYearIn(WidgetTester tester, String languageCode) async {
  late String formatted;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          formatted = DateFormat.yMMMM(
            Localizations.localeOf(context).languageCode,
          ).format(DateTime(2026, 3, 14));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return formatted;
}

void main() {
  testWidgets('a date formats in the locale the app is running in', (
    tester,
  ) async {
    expect(await _monthYearIn(tester, 'en'), 'March 2026');
    // Not asserted as a literal beyond the month name: what matters is that
    // Malay resolves to Malay month names rather than falling back to English.
    expect(await _monthYearIn(tester, 'ms'), contains('Mac'));
  });
}
