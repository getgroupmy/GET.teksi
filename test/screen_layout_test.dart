import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/widgets/ui.dart';

import 'support/screens.dart';

/// Where things sit on the screen.
///
/// Both failures below are the same shape, and I made both of them: while
/// fixing an overflow, a widget that positions its child was swapped for one
/// that does not. Neither is an overflow, neither is an unlabelled control, so
/// neither the text-scale gate nor the semantics gate can see it — every
/// assertion stays true while the screen is plainly wrong.

/// The two home screens float their controls over a map, and that bar belongs
/// at the top.
///
/// This exists because it did not stay there. Replacing a `Spacer`/`Flexible`
/// pair with `Expanded(child: Center(...))` on DriverHome stretched the Row to
/// the full height of the Stack — `Center` has no height factor, so it fills
/// whatever it is given — and `crossAxisAlignment.center` then parked the menu
/// button, the earnings pill and the notification bell in the **vertical
/// middle of the screen**, floating over the map with the OpenStreetMap
/// attribution underneath.
///
/// Nothing caught it. It is not an overflow, so the text-scale gate passed. It
/// is not a missing label, so the semantics gate passed. Every control was
/// present, laid out, inside the viewport and reachable — just in the wrong
/// half of the screen. It took rendering the real web build in a browser and
/// looking at it.
///
/// The giveaway was that the button's centre landed on exactly 426.0 of an
/// 852-pixel screen. A bar deliberately placed above a sheet does not land on
/// 50.000% of the viewport; a stretched Row centring its children does.
void main() {
  final app = ScreenFixture();

  setUp(() async => app.reset());

  /// How far the first control's top edge may sit from the top of the screen.
  /// The bar's own padding is 8, so this leaves room for a tweak without
  /// leaving room for it to drift into the middle.
  const tolerance = 80.0;

  for (final name in ['DriverHomeScreen', 'PassengerHomeScreen']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$name keeps its top bar at the top at ${scale}x', (
        tester,
      ) async {
        app.sizeAsPhone(tester);
        await tester.pumpWidget(app.wrap(app.screens()[name]!(), scale: scale));
        await tester.pump(const Duration(milliseconds: 350));

        final menu = find.byType(FabButton).first;
        final rect = tester.getRect(menu);
        final height =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;

        expect(
          rect.top,
          lessThan(tolerance),
          reason:
              '$name at ${scale}x puts its first top-bar control at '
              'y=${rect.top}, on a screen $height tall. It belongs within '
              '$tolerance of the top. A control that drifts to the middle is '
              'still present, still labelled and still inside the viewport, '
              'so no other gate here will notice.',
        );
      });
    }
  }

  // -------------------------------------------------------------------------

  /// The intro slide is centred in the space between the wordmark and the
  /// page dots.
  ///
  /// It stopped being: a bare `SingleChildScrollView`, added so the slide
  /// could scroll at a large text size, sizes its child to the child's own
  /// height and pins it to the top — so the icon, heading and body sat jammed
  /// under the header with the rest of the screen empty. The fix gives the
  /// scroll view a minimum height of the viewport so the `Center` inside it
  /// still has room to work.
  testWidgets('IntroScreen keeps its slide centred', (tester) async {
    app.sizeAsPhone(tester);
    await tester.pumpWidget(app.wrap(app.screens()['IntroScreen']!()));
    await tester.pump(const Duration(milliseconds: 350));

    final slide = find.byType(AnimatedSwitcher);
    final rect = tester.getRect(slide);
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // Equal-ish space above and below. Generous, because the header and the
    // dots are not symmetric — but nowhere near satisfied by a slide pinned
    // to the top, which is what this is for.
    final above = rect.top;
    final below = height - rect.bottom;
    expect(
      (above - below).abs(),
      lessThan(height * 0.25),
      reason:
          'The intro slide sits ${above.toStringAsFixed(0)} from the top and '
          '${below.toStringAsFixed(0)} from the bottom, on a screen $height '
          'tall. It should be roughly centred; this far out means something '
          'stopped centring it.',
    );
  });
}
