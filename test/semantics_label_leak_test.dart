import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screens.dart';

/// A `Semantics` label that is not what gets read out.
///
/// `Semantics(label: x, child: …)` does not replace what the child announces,
/// it adds to it. Flutter merges the two, so a label written to be the whole
/// announcement ends up with the child's visible text stuck on the end. The
/// driver home read:
///
///     "Earnings, RM18,945.00, offline RM18,945 Off"
///
/// — the amount twice and a trailing "Off", because the tile draws "RM18,945"
/// and "Off" under the label that already said both. The notification bell
/// read "Notifications, 1 unread 1": the badge number again, as a bare digit.
/// `excludeSemantics: true` is what makes the label the whole announcement.
///
/// test/semantics_test.dart cannot see this. Its question is whether a control
/// announces *something*, and these announce plenty. The difference only shows
/// up by comparing what was written against what came out, which is what this
/// does: every `Semantics` widget that declares a label is asked what the
/// rendered node's label actually is.
///
/// Found by reading Chromium's own accessibility tree — the tree a screen
/// reader consumes — against the web build, screen by screen.
void main() {
  final app = ScreenFixture();
  setUp(() async => app.reset());

  Future<SemanticsHandle> pump(WidgetTester tester, Widget screen) async {
    final handle = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app.wrap(screen));
    await tester.pump(const Duration(milliseconds: 350));
    return handle;
  }

  /// What was written, against what is read out.
  ///
  /// Only a node whose label *begins with* the declared one is a finding, and
  /// that is deliberate. `tester.getSemantics` answers with the nearest node,
  /// which for a widget merged into an ancestor is the ancestor's — so a
  /// mismatch on its own means either this bug or "that label belongs to some
  /// other node", and the two are not worth confusing. When the declared text
  /// is the start of what is read and something follows it, the something is
  /// the child's, and that is the bug exactly.
  ///
  /// It follows that this cannot see a label with the child's text merged in
  /// *front* of it, and does not try to. An icon's `semanticLabel` inside a
  /// merged row is also not a finding: there the label is a contribution to a
  /// longer sentence rather than the whole of one, which is what the
  /// EarningsScreen rating is.
  List<String> leaks(WidgetTester tester) {
    final found = <String>[];
    for (final element in find.byType(Semantics).evaluate()) {
      final widget = element.widget as Semantics;
      final declared = widget.properties.label;
      if (declared == null || declared.isEmpty) continue;
      final spoken = tester.getSemantics(find.byWidget(widget)).label;
      if (spoken != declared && spoken.startsWith(declared)) {
        found.add('wrote "$declared"\n   read  "$spoken"');
      }
    }
    return found;
  }

  app.screens().forEach((name, build) {
    testWidgets(name, (tester) async {
      final handle = await pump(tester, build());
      expect(
        leaks(tester),
        isEmpty,
        reason:
            'On $name a Semantics label is not the whole announcement — the '
            "child's text is merged onto it. Pass excludeSemantics: true so "
            'the label is what a screen reader reads:\n'
            '${leaks(tester).join('\n')}',
      );
      handle.dispose();
    });
  });

  group('the gate itself', () {
    testWidgets('catches a label with the child merged onto it', (
      tester,
    ) async {
      final handle = await pump(
        tester,
        Scaffold(
          body: Semantics(
            button: true,
            label: 'Earnings, RM18,945.00, offline',
            child: const Column(children: [Text('RM18,945'), Text('Off')]),
          ),
        ),
      );
      // Not hasLength(1): the wrapper this pumps through may carry labelled
      // Semantics of its own. What matters is that this tree is reported.
      expect(
        leaks(tester).where((l) => l.contains('Earnings, RM18,945.00')),
        hasLength(1),
      );
      handle.dispose();
    });

    testWidgets('passes the same tree with excludeSemantics', (tester) async {
      final handle = await pump(
        tester,
        Scaffold(
          body: Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Earnings, RM18,945.00, offline',
            child: const Column(children: [Text('RM18,945'), Text('Off')]),
          ),
        ),
      );
      expect(
        leaks(tester).where((l) => l.contains('Earnings, RM18,945.00')),
        isEmpty,
      );
      handle.dispose();
    });
  });
}
