import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('the gate itself', () {
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
