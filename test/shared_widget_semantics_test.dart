import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/formats.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/theme.dart';
import 'package:get_teksi/widgets/ui.dart';

import 'support/semantics.dart';

/// What `Avatar` and `RatingChip` say, which is what twelve files say.
///
/// Both were found by reading Chromium's accessibility tree against the web
/// build. The menu row read:
///
///     "NA Nurul Ain binti Abdullah 4.9 1204 trips given"
///
/// — the avatar's initials spoken as though they were a word, and a bare
/// "4.9" with nothing saying what it counts. Neither is a judgement call
/// about wording: initials are a picture of a name, and a number with no
/// noun is the same defect the earnings rating had in #27.
///
/// These are unit tests of the two widgets rather than another walk of the
/// screens, because the widgets are what the screens share. Fixing them once
/// fixed twelve files, and a test of one screen would say nothing about the
/// other eleven.
void main() {
  Future<SemanticsHandle> show(WidgetTester tester, Widget child) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pump();
    return handle;
  }

  List<String> labelsOn(WidgetTester tester) =>
      flattenSemantics(tester.getSemantics(find.byType(Scaffold)))
          .map((n) => n.label)
          .where((l) => l.trim().isNotEmpty)
          .toList();

  group('Avatar', () {
    const name = 'Nurul Ain binti Abdullah';

    testWidgets('says nothing, because its initials are a picture', (
      tester,
    ) async {
      final handle = await show(
        tester,
        const Avatar(name: name, color: 0xFF4CAF50),
      );
      expect(
        labelsOn(tester),
        isEmpty,
        reason:
            'the initials were announced as a word beside the name they '
            'stand for',
      );
      handle.dispose();
    });

    testWidgets('and the initials really are what it draws', (tester) async {
      // Without this the test above would pass just as well on an Avatar
      // that had stopped drawing anything at all.
      final handle = await show(
        tester,
        const Avatar(name: name, color: 0xFF4CAF50),
      );
      expect(find.text(initials(name)), findsOneWidget);
      expect(initials(name), 'NA');
      handle.dispose();
    });

    testWidgets('says what it is given, and only that', (tester) async {
      final handle = await show(
        tester,
        const Avatar(
          name: name,
          color: 0xFF4CAF50,
          semanticLabel: 'Your profile',
        ),
      );
      expect(
        labelsOn(tester),
        ['Your profile'],
        reason:
            'a label on the avatar must replace the initials rather than '
            'have them merged onto the end of it',
      );
      handle.dispose();
    });
  });

  group('RatingChip', () {
    testWidgets('says what the number counts', (tester) async {
      final handle = await show(tester, const RatingChip(value: 4.92));
      final l = await AppLocalizations.delegate.load(const Locale('en'));

      expect(labelsOn(tester), [l.ratingValue('4.9')]);
      expect(
        labelsOn(tester).single,
        isNot('4.9'),
        reason: 'a bare number is what this was before',
      );
      handle.dispose();
    });

    testWidgets('in the other language too', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(dark: true),
          locale: const Locale('ms'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: RatingChip(value: 4.92))),
        ),
      );
      await tester.pump();

      final ms = await AppLocalizations.delegate.load(const Locale('ms'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(labelsOn(tester), [ms.ratingValue('4.9')]);
      expect(
        ms.ratingValue('4.9'),
        isNot(en.ratingValue('4.9')),
        reason:
            'a label spoken in English to a Malay speaker is the bug '
            'one layer down',
      );
      handle.dispose();
    });
  });
}
