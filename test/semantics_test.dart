import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/l10n/app_localizations.dart';

import 'support/screens.dart';
import 'support/semantics.dart';

/// What every screen hands a screen reader.
///
/// The audit recorded this as not done: "Semantic labels were added to the
/// icon-only controls, but the full focus order has not been audited with a
/// real screen reader." One screen has a test — test/otp_semantics_test.dart,
/// written after the one-time-code field turned out to be missing from the
/// semantics tree entirely, which with VoiceOver or TalkBack running meant the
/// code could not be typed at all and sign-in was shut. Sign-in is phone plus
/// that code, so a single unlabelled subtree closed the whole app.
///
/// That is the class of bug this walks all 23 screens for. It is not a
/// substitute for turning on a screen reader and listening — reading order and
/// whether a label makes sense out loud are not things a widget test can judge
/// — but the two failures below are mechanical, and mechanical failures are
/// what a gate is for:
///
///   * a control that announces nothing, so a screen reader says "button" and
///     the user has to guess;
///   * an input missing from the tree, which is unusable rather than merely
///     unlabelled, because Flutter routes typing through the semantics node
///     when a screen reader is attached.

void main() {
  final app = ScreenFixture();

  setUp(() async {
    await app.reset();
  });

  /// Pumps the screen with the semantics tree switched on and hands back its
  /// root. Semantics is off by default in tests, and a tree nobody asked for
  /// is an empty one — which would make every assertion below pass.
  Future<({SemanticsNode root, SemanticsHandle handle})> pump(
    WidgetTester tester,
    Widget screen,
  ) async {
    final handle = tester.ensureSemantics();
    app.sizeAsPhone(tester);
    await tester.pumpWidget(app.wrap(screen));
    await tester.pump(const Duration(milliseconds: 350));
    // getSemantics rather than reaching for the binding's semantics owner:
    // it is the supported route, and it resolves to the node *enclosing* the
    // Scaffold, which is the root — so walking down from it covers the whole
    // screen. Every screen in the app has a Scaffold; `.first` is for the
    // ones that nest another inside a sheet.
    return (
      root: tester.getSemantics(find.byType(Scaffold).first),
      handle: handle,
    );
  }

  group('every control announces itself', () {
    app.screens().forEach((name, _) {
      testWidgets(name, (tester) async {
        final (root: root, handle: handle) = await pump(
          tester,
          app.screens()[name]!(),
        );

        final silent = controls(root).where((n) => !announcesSomething(n));
        expect(
          silent.map(describeNode).toList(),
          isEmpty,
          reason:
              'On $name a screen reader would reach these and have nothing '
              'to read out. An icon-only control needs a tooltip or a '
              'Semantics label; the icon itself is not one.',
        );
        handle.dispose();
      });
    });
  });

  group('every input is reachable', () {
    app.screens().forEach((name, _) {
      testWidgets(name, (tester) async {
        final (root: root, handle: handle) = await pump(
          tester,
          app.screens()[name]!(),
        );

        // Only screens that actually have a field: asserting a text field on
        // a screen with none would be asserting the opposite of the truth.
        final fieldsOnScreen = find.byType(EditableText).evaluate().length;
        final fieldsInTree = flattenSemantics(root)
            .where((n) => n.flagsCollection.isTextField)
            .length;

        if (fieldsOnScreen > 0) {
          expect(
            fieldsInTree,
            greaterThan(0),
            reason:
                '$name draws $fieldsOnScreen text field(s) and exposes none '
                'to the semantics tree. With a screen reader attached '
                'Flutter routes typing through that node, so there is '
                'nothing to type into — the screen is unusable, not just '
                'unlabelled. This is the OtpScreen bug.',
          );
        }
        handle.dispose();
      });
    });
  });

  /// Two controls on one screen that say the same thing.
  ///
  /// Reaching a list of buttons that all announce "Use" tells a screen
  /// reader user how many there are and nothing about which is which. That
  /// was the Promos screen until #27: three promo cards, three buttons, one
  /// word between them, because the code that distinguishes them is in a
  /// separate Text beside each button rather than in it.
  ///
  /// Distinct names are not a style preference here — they are the only way
  /// to tell the controls apart without sight. No screen has a duplicate
  /// today, so this is a line that holds rather than a cleanup to do.
  group('no two controls say the same thing', () {
    app.screens().forEach((name, _) {
      testWidgets(name, (tester) async {
        final (root: root, handle: handle) = await pump(
          tester,
          app.screens()[name]!(),
        );

        final spoken = controls(root)
            .map((n) => n.label.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        final repeated = {
          for (final l in spoken)
            if (spoken.where((o) => o == l).length > 1) l,
        };

        expect(
          repeated,
          isEmpty,
          reason:
              'On $name these are said by more than one control, so a '
              'screen reader user has no way to tell those controls '
              'apart:\n${repeated.join('\n')}',
        );
        handle.dispose();
      });
    });
  });

  /// One screen's own regression, because the rule it broke is not one a
  /// gate can state. "Add" beside a section heading reads fine and hears
  /// badly: the heading is not announced with the button, so it said "Add"
  /// and nothing else — on the screen where what is being added is who gets
  /// called if someone presses SOS.
  ///
  /// It is here rather than in the audit's "needs a person with VoiceOver"
  /// list, where I put it twice, because the words already existed: it is
  /// the title of the sheet the button opens.
  testWidgets('SafetyScreen says what the Add button adds', (tester) async {
    final (root: root, handle: handle) = await pump(
      tester,
      app.screens()['SafetyScreen']!(),
    );
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    final spoken = controls(root).map((n) => n.label.trim()).toList();
    expect(spoken, contains(l.addEmergencyContact));
    expect(
      spoken,
      isNot(contains(l.add)),
      reason: 'a bare "Add" is what this said before',
    );
    handle.dispose();
  });

  group('the gate itself', () {
    testWidgets('catches two controls that say the same thing', (tester) async {
      final (root: root, handle: handle) = await pump(
        tester,
        Scaffold(
          body: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('Use')),
              TextButton(onPressed: () {}, child: const Text('Use')),
            ],
          ),
        ),
      );
      final spoken = controls(root).map((n) => n.label.trim()).toList();
      expect(spoken.where((l) => l == 'Use'), hasLength(2));
      handle.dispose();
    });

    testWidgets('catches a control that announces nothing', (tester) async {
      final (root: root, handle: handle) = await pump(
        tester,
        // An icon-only button with no tooltip: exactly what the first group
        // is looking for.
        Scaffold(
          body: Center(
            child: IconButton(icon: const Icon(Icons.close), onPressed: () {}),
          ),
        ),
      );
      final silent = controls(root).where((n) => !announcesSomething(n));
      expect(
        silent,
        isNotEmpty,
        reason:
            'an unlabelled IconButton was not flagged, so the suite above '
            'is not testing anything',
      );
      handle.dispose();
    });

    testWidgets('catches an input dropped from the tree', (tester) async {
      final (root: root, handle: handle) = await pump(
        tester,
        // Opacity drops a fully transparent subtree from the semantics tree
        // unless told otherwise. This is the OtpScreen bug in miniature.
        const Scaffold(body: Opacity(opacity: 0, child: TextField())),
      );
      expect(
        find.byType(EditableText).evaluate(),
        isNotEmpty,
        reason: 'the field should be drawn, or this proves nothing',
      );
      expect(
        flattenSemantics(root).where((n) => n.flagsCollection.isTextField),
        isEmpty,
        reason:
            'a field hidden behind Opacity was still exposed, so the second '
            'suite above is not testing anything',
      );
      handle.dispose();
    });
  });
}
