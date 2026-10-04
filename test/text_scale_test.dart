import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screens.dart';

/// Every screen, laid out at double the system text size.
///
/// The accessibility audit (docs/UI-UX-AUDIT.md) fixed the rows that were
/// obviously brittle and recorded the rest as not done: "the app has not been
/// walked end to end at maximum system text size". This walks it, on every
/// build, so that the answer stops depending on whether anyone remembered to
/// look.
///
/// Worth saying what the failure actually looks like, because it is not a
/// crash. A `Row` of two labels that no longer fit paints a yellow-and-black
/// stripe in debug and silently clips in release — the words are simply gone,
/// with nothing in any log. Someone who has turned text size up is exactly the
/// person who cannot read what is left.
///
/// The app does not clamp the scale anywhere: `MaterialApp.router` in
/// main.dart passes the platform's value straight through, so 2.0 is a setting
/// a real user can choose. Android's accessibility slider reaches it, and
/// iOS's larger accessibility sizes go beyond — so this is a floor, not a
/// ceiling.
void main() {
  final app = ScreenFixture();

  setUp(() async {
    await app.reset();
  });

  /// Lays the screen out the way the app does, at [scale] times the normal
  /// text size, and returns a description of the first complaint, or null.
  ///
  /// The complaint is collected through `FlutterError.onError` rather than
  /// `tester.takeException()` because `takeException` hands back only the
  /// message — "overflowed by 305 pixels on the right" — and then whoever
  /// reads the failure has to go and find the row by hand. The error's
  /// `debugCreator` carries the widget ancestry, which names it.
  Future<String?> layout(
    WidgetTester tester,
    Widget screen, {
    required double scale,
  }) async {
    final complaints = <String>[];
    final previousOnError = FlutterError.onError;
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
    addTearDown(() => FlutterError.onError = previousOnError);

    app.sizeAsPhone(tester);
    await tester.pumpWidget(app.wrap(screen, scale: scale));
    // Overflow is reported from paint, so one frame is enough to catch it —
    // but a screen that starts an animation or a timer settles into a
    // different layout, and that one has to fit as well. Not pumpAndSettle:
    // the map and the offer countdown never stop, so it would time out.
    await tester.pump(const Duration(milliseconds: 350));
    FlutterError.onError = previousOnError;
    return complaints.isEmpty ? null : complaints.first;
  }

  group('at the normal text size', () {
    // The control. If a screen cannot lay out at 1.0 then the 2.0 failure
    // below says nothing about text size, and this is where to look first.
    // It has already earned its place: the first version of this suite failed
    // on every screen because the session was signed out and they threw on a
    // null check before laying out at all.
    app.screens().forEach((name, _) {
      testWidgets('$name lays out', (tester) async {
        final error = await layout(tester, app.screens()[name]!(), scale: 1.0);
        expect(error, isNull, reason: '$name at 1.0x: $error');
      });
    });
  });

  group('at double the text size', () {
    app.screens().forEach((name, _) {
      testWidgets('$name lays out', (tester) async {
        final error = await layout(tester, app.screens()[name]!(), scale: 2.0);
        expect(
          error,
          isNull,
          reason:
              '$name overflows at 2.0x text scale. Someone who has turned '
              'text size up loses whatever is past the edge, with no error '
              'anywhere in release. $error',
        );
      });
    });
  });

  group('the gate itself', () {
    // Without this the suite above could pass because overflow is not being
    // reported at all — a mistake in `layout` would read as 23 clean screens.
    testWidgets('catches an overflow that is really there', (tester) async {
      final error = await layout(
        tester,
        // 600 logical pixels of content in a column that is at most 480 wide.
        Scaffold(
          body: Row(
            children: [Container(width: 600, height: 20, color: Colors.red)],
          ),
        ),
        scale: 1.0,
      );
      expect(
        error,
        isNotNull,
        reason:
            'a deliberate overflow was not reported, so the suite above '
            'is not testing anything',
      );
      expect(error, contains('overflowed'));
      // And that the ancestry made it into the message, which is the only
      // thing that turns a failure into a place to look.
      expect(error, contains('in Row'));
    });
  });
}
