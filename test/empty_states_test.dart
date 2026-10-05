import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/widgets/ui.dart';

import 'support/screens.dart';
import 'support/semantics.dart';

/// Every screen as a new account sees it.
///
/// `_populate()` in support/screens.dart fills the lists, and it is there for
/// a good reason: without it the gates were laying out empty screens and
/// counting them as covered — NotificationsScreen rendered three `Text`s and
/// zero `Row`s and still appeared in both gates' reports.
///
/// But every gate resets the same way, so filling the lists made the other
/// half unreachable. `EmptyState(` appears in ten files and no test had ever
/// rendered one: the only mention of it anywhere under test/ was the comment
/// explaining why the fixture stops them happening.
///
/// Empty is not an edge case here. It is the first thing a new account sees —
/// History, Wallet, Notifications and Earnings all open on it — and it had
/// never been laid out at double the text size, never in the other language
/// the app ships, and never walked for what a screen reader is given.
///
/// Six of those ten files need a condition this does not produce: no ride, no
/// documents, no messages. A missing ride has its own tests in
/// error_states_test.dart. What this covers is the day-one account.
void main() {
  final app = ScreenFixture();

  setUp(() async => app.reset(populate: false));

  /// The screens that really do go empty for a new account.
  ///
  /// Named rather than counted, and asserted below, because this gate is
  /// worth exactly as much as the emptiness is real. If a future fixture
  /// change quietly repopulates one of these, the walk would go on passing
  /// while measuring a screen with rows in it — which is the failure this
  /// whole file exists to answer.
  const goesEmpty = {
    'EarningsScreen',
    'WalletScreen',
    'HistoryScreen',
    'NotificationsScreen',
  };

  /// Lays the screen out and returns the first overflow complaint, or null.
  ///
  /// Collected through `FlutterError.onError`, as text_scale_test does, and
  /// restored before returning so the binding does not assert about an
  /// override left in place while expect() runs.
  Future<String?> layout(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    required Locale locale,
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
    FlutterError.onError = previous;
    return complaints.isEmpty ? null : complaints.first;
  }

  group('the fixture really is empty', () {
    for (final name in goesEmpty) {
      testWidgets('$name draws its empty state', (tester) async {
        await layout(
          tester,
          app.screens()[name]!(),
          scale: 1.0,
          locale: const Locale('en'),
        );
        expect(
          find.byType(EmptyState),
          findsOneWidget,
          reason:
              '$name has rows in it with populate: false, so everything this '
              'file measures for it is the populated screen again and the '
              'empty one is still unrendered.',
        );
      });
    }

    // The other direction, so "empty" cannot come to mean "always empty".
    //
    // In a group's setUp, not in the test body: RidesStore starts a three
    // second periodic timer, and a store built inside the body is built
    // inside the fake-async zone, where that timer is tracked and the test
    // ends on "A Timer is still pending". setUp runs outside it. The outer
    // setUp has already run by then, so this is the second reset of the test
    // and the first store's timer is cancelled by reset itself.
    group('and the populated fixture is not', () {
      setUp(() async => app.reset());

      testWidgets('HistoryScreen has rows', (tester) async {
        await layout(
          tester,
          app.screens()['HistoryScreen']!(),
          scale: 1.0,
          locale: const Locale('en'),
        );
        expect(find.byType(EmptyState), findsNothing);
      });
    });
  });

  // The other half of what "never rendered" cost. An empty screen is mostly a
  // centred icon and two lines of text, and the controls that remain are the
  // app bar's and whatever the empty state offers — a different set from the
  // populated screen's, asked the same question semantics_test.dart asks.
  group('every control on an empty screen announces itself', () {
    app.screens().forEach((name, build) {
      testWidgets(name, (tester) async {
        final handle = tester.ensureSemantics();
        app.sizeAsPhone(tester);
        await tester.pumpWidget(app.wrap(build()));
        await tester.pump(const Duration(milliseconds: 350));

        final root = tester.getSemantics(find.byType(Scaffold).first);
        final silent = controls(root).where((n) => !announcesSomething(n));
        expect(
          silent.map(describeNode).toList(),
          isEmpty,
          reason:
              'On $name with nothing in it a screen reader would reach these '
              'and have nothing to read out.',
        );
        handle.dispose();
      });
    });
  });

  group('the gate itself', () {
    testWidgets('catches an overflow that is really there', (tester) async {
      // This file carries its own copy of the capture above, so a mistake in
      // it would make every layout check pass without measuring anything.
      //
      // Horizontal, like the same check in text_scale_test.dart: `wrap`
      // gives the screen a 480 pixel column and unbounded height, so a tall
      // Column simply grows and never overflows. 600 in 480 does.
      final error = await layout(
        tester,
        Scaffold(
          body: Row(
            children: [Container(width: 600, height: 20, color: Colors.red)],
          ),
        ),
        scale: 1.0,
        locale: const Locale('en'),
      );
      expect(
        error,
        isNotNull,
        reason:
            'a deliberate overflow was not reported, so the walk above is '
            'measuring nothing',
      );
      expect(error, contains('overflowed'));
      expect(error, contains('in Row'));
    });
  });

  for (final locale in appLocales) {
    final lang = locale.languageCode;
    for (final scale in [1.0, 2.0]) {
      group('empty, in $lang at ${scale}x', () {
        app.screens().forEach((name, _) {
          testWidgets('$name lays out', (tester) async {
            final error = await layout(
              tester,
              app.screens()[name]!(),
              scale: scale,
              locale: locale,
            );
            expect(
              error,
              isNull,
              reason:
                  '$name with nothing in it overflows in $lang at ${scale}x. '
                  'This is what a new account opens on, and an overflowing '
                  'RenderFlex drops the text silently in release:\n$error',
            );
          });
        });
      });
    }
  }
}
