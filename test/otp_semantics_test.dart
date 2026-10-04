import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/screens/auth/otp_screen.dart';
import 'package:get_teksi/theme.dart';

/// The one-time code screen draws six boxes and puts a fully transparent
/// TextField on top of them, which is the ordinary way to build this control.
/// The ordinary way has a trap in it: `Opacity` drops a fully transparent
/// subtree from the semantics tree unless told otherwise, and that field is the
/// only input on the screen.
///
/// The consequence is worse than an unlabelled control. With a screen reader
/// running, Flutter routes text input through the semantics node rather than
/// its own editing host — so there is nothing to type into, and the code cannot
/// be entered at all. Sign-in is phone plus this code, so the whole app is shut
/// to a VoiceOver or TalkBack user. Found by driving the built app in a
/// browser with accessibility switched on, where the field simply was not in
/// the DOM.

/// Whether anything in the tree announces itself as somewhere you can type.
///
/// A walk rather than `tester.getSemantics(find.byType(TextField))`: that
/// resolves to the nearest *enclosing* node, which for a field whose own node
/// has been dropped is simply the root — indistinguishable from a field that
/// was never there.
bool _hasTextField(SemanticsNode node) {
  if (node.flagsCollection.isTextField) return true;
  var found = false;
  node.visitChildren((child) {
    found = found || _hasTextField(child);
    return true;
  });
  return found;
}

/// Every label the tree offers, in order.
List<String> _labels(SemanticsNode node) {
  final out = <String>[];
  void walk(SemanticsNode n) {
    final label = n.label.trim();
    if (label.isNotEmpty) out.add(label);
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(node);
  return out;
}

void main() {
  Future<SemanticsHandle> pumpOtp(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OtpScreen(phone: '+60123456789'),
      ),
    );
    await tester.pump();
    return handle;
  }

  /// The nearest semantics node to the whole screen, to walk down from.
  SemanticsNode root(WidgetTester tester) =>
      tester.getSemantics(find.byType(Scaffold));

  testWidgets('the code field exists for a screen reader', (tester) async {
    final handle = await pumpOtp(tester);

    expect(
      _hasTextField(root(tester)),
      isTrue,
      reason:
          'The transparent TextField is the only way to enter the code. '
          'Dropped from the semantics tree, a screen reader user cannot '
          'sign in at all.',
    );
    handle.dispose();
  });

  testWidgets('the six boxes are not read out one digit at a time', (
    tester,
  ) async {
    // They are decoration: each holds a single character of a code the user
    // just typed. Announcing them separately turns one number into six
    // meaningless utterances between the heading and the button.
    final handle = await pumpOtp(tester);

    // Three digits, not six: an empty box holds an empty string and announces
    // nothing at all, so the boxes only become noisy once something is in
    // them — and six would submit the form, which wants a router.
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();

    final labels = _labels(root(tester));
    expect(labels, isNotEmpty, reason: 'the screen should announce something');
    // Nothing that is a bare single character.
    expect(
      labels.where((l) => l.length == 1),
      isEmpty,
      reason: 'found single-character semantics: $labels',
    );
    handle.dispose();
  });

  testWidgets('the heading and the button still are read out', (tester) async {
    // The counterpart to the test above: excluding the boxes must not take
    // the rest of the screen with it.
    final handle = await pumpOtp(tester);

    final labels = _labels(root(tester)).join(' | ');
    expect(labels, contains('Enter the code'));
    expect(labels, contains('Verify'));
    handle.dispose();
  });
}
