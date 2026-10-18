import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/router.dart';
import 'package:get_teksi/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'support/screens.dart';

/// The browser's Back button, which nothing had ever pressed.
///
/// `ride_flow_test.dart` walks the router forwards — a screen navigates, and
/// the question is where the router put you. Backwards is a different
/// mechanism entirely and the app ships on the web, where Back is a button
/// every user has and some use instead of the one on the screen.
///
/// On the web a location change is a browser history entry. go_router reports
/// `replace: false` for every one of them bar the first — see
/// `GoRouteInformationProvider.routerReportsNewRouteInformation`, where the
/// `none` case resolves to `_valueInEngine == _kEmptyRouteInformation` — so a
/// redirect writes history exactly like a tap does. That makes a guarded
/// location behind you a trap, and the trap is measured at the bottom of this
/// file.
void main() {
  final app = ScreenFixture();
  late GoRouterConfig config;

  setUp(() async => app.reset());

  String here() => config
      .router
      .routerDelegate
      .currentConfiguration
      .matches
      .last
      .matchedLocation;

  Future<void> settle(WidgetTester tester) async {
    // Not pumpAndSettle: the map and the countdowns never stop, so it would
    // time out rather than settle. Four frames, because a navigation driven
    // from a post-frame callback needs them.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 350));
    }
  }

  Future<History> start(
    WidgetTester tester,
    Role role,
    String at, {
    bool signedOut = false,
  }) async {
    final history = History(tester);
    app.session.setRole(role);
    if (signedOut) app.session.signOut();
    config = GoRouterConfig(app.session);
    addTearDown(config.dispose);
    config.router.go(at);

    app.sizeAsPhone(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app.session),
          ChangeNotifierProvider.value(value: app.rides),
          ChangeNotifierProvider.value(value: app.draft),
          Provider<Notifier>.value(value: const SilentNotifier()),
        ],
        child: MaterialApp.router(
          theme: buildTheme(dark: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: config.router,
        ),
      ),
    );
    await settle(tester);
    return history;
  }

  /// Presses Back until the history runs out, and says how many presses that
  /// took — or null if it never ran out.
  ///
  /// Running out is what leaving the app looks like: the entry the app was
  /// loaded into is the last one, and the press after that belongs to
  /// whatever the browser was showing before. Never running out is the
  /// defect, because each press is spending an entry and something is
  /// putting one back.
  Future<int?> pressBackUntilOut(
    WidgetTester tester,
    History history, {
    int limit = 20,
  }) async {
    for (var presses = 1; presses <= limit; presses++) {
      if (!history.canGoBack) return presses - 1;
      await history.back();
      await settle(tester);
    }
    return history.canGoBack ? null : limit;
  }

  group('the harness', () {
    // This file reports a defect, so the thing doing the reporting has to be
    // worth believing. Each of these fails if the model of the browser stops
    // matching the contract it is modelling.
    testWidgets('a location change adds an entry, and Back spends it', (
      tester,
    ) async {
      final h = await start(tester, Role.passenger, '/p');
      expect(h.length, 1);
      config.router.push('/menu');
      await settle(tester);
      expect(h.length, 2, reason: 'a push is a pushState');
      await h.back();
      await settle(tester);
      expect(h.length, 1);
    });

    testWidgets('`replace: true` overwrites the entry instead of adding one', (
      tester,
    ) async {
      final h = History(tester);
      await h.pretendTheAppReported('/a', replace: false);
      await h.pretendTheAppReported('/b', replace: false);
      expect(h.length, 2);
      await h.pretendTheAppReported('/c', replace: true);
      expect(h.length, 2);
      expect(h.top, '/c');
    });

    testWidgets('Back carries the entry\'s state, not just its URL', (
      tester,
    ) async {
      // go_router puts its encoded match list in `state` and rebuilds the
      // whole page stack from it, so a model that replayed the URL alone
      // would restore a different stack than the browser does. Two pushes
      // leave the URL at /p throughout — `push` does not change it — so the
      // only thing telling /menu from /profile here is the state.
      final h = await start(tester, Role.passenger, '/p');
      config.router.push('/menu');
      await settle(tester);
      config.router.push('/profile');
      await settle(tester);
      expect(h.entries.map((e) => e.uri), everyElement('/p'));
      expect(h.entries.last.state, isNotNull);

      await h.back();
      await settle(tester);
      expect(
        here(),
        '/menu',
        reason:
            'the stack came back from the entry state. Dropping state from '
            'this model would land on /p and look like a working Back.',
      );
    });

    testWidgets('an entry with no state is not a browser entry', (
      tester,
    ) async {
      // Worth pinning, because it is what a hand-written fixture gets wrong.
      // `_platformReportsNewRouteInformation` treats a null state as "this
      // did not come from us" and clears `_valueInEngine`, which makes the
      // app's next report a `replace` rather than a push. A model that
      // seeded entries with a null state therefore shows a redirect
      // collapsing its own entry — and a loop looking fixed when it is not.
      final h = await start(tester, Role.passenger, '/p');
      app.session.setRole(Role.driver);
      config.router.go('/d');
      await settle(tester);
      expect(h.length, 2);

      h.entries[0] = Entry('/p', null);
      await h.back();
      await settle(tester);
      expect(
        h.length,
        1,
        reason:
            'with a null state the redirect replaced its entry. This is the '
            'artefact, not the browser: every real entry carries the state '
            'go_router wrote with it.',
      );
    });

    testWidgets('pressBackUntilOut reports null only for a real loop', (
      tester,
    ) async {
      // The shape under test, with no app in it. A loop needs three things:
      // an entry behind you, a guard that refuses *that* location, and a
      // different location to be sent to. Refusing the location you are
      // already at is not enough — the inbound then matches the provider's
      // current value exactly, `_platformReportsNewRouteInformation` returns
      // early, and the press simply spends its entry. Which is why this
      // flips the guard on after arriving, the way switching role does.
      final h = History(tester);
      var refuseA = false;
      final looping = GoRouter(
        initialLocation: '/a',
        redirect: (_, state) =>
            refuseA && state.matchedLocation == '/a' ? '/b' : null,
        routes: [
          GoRoute(path: '/a', builder: (_, _) => const Text('a')),
          GoRoute(path: '/b', builder: (_, _) => const Text('b')),
        ],
      );
      addTearDown(looping.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: looping));
      await settle(tester);
      expect(h.length, 1);

      refuseA = true;
      looping.go('/b');
      await settle(tester);
      expect(h.length, 2, reason: 'the /a entry is behind us and now refused');

      expect(
        await pressBackUntilOut(tester, h, limit: 6),
        isNull,
        reason: 'a guard that refuses what Back lands on never drains',
      );
    });

    testWidgets('and reports a count for a journey that does drain', (
      tester,
    ) async {
      // The other direction. Without this the counter could return null for
      // everything and every defect below would look confirmed.
      final h = await start(tester, Role.passenger, '/p');
      config.router.push('/menu');
      await settle(tester);
      expect(await pressBackUntilOut(tester, h), 1);
    });
  });

  group('Back works', () {
    testWidgets('through pushed screens, and then out of the app', (
      tester,
    ) async {
      final h = await start(tester, Role.passenger, '/p');
      config.router.push('/menu');
      await settle(tester);
      config.router.push('/profile');
      await settle(tester);
      expect(here(), '/profile');

      await h.back();
      await settle(tester);
      expect(here(), '/menu');
      await h.back();
      await settle(tester);
      expect(here(), '/p');
      expect(
        h.canGoBack,
        isFalse,
        reason: 'the next press belongs to the page before the app',
      );
    });

    testWidgets('off the rating screen, which pushes itself', (tester) async {
      // PassengerHomeScreen pushes /rate from a post-frame callback whenever a
      // ride is awaiting one, so Back landing on the home screen could push
      // it straight back and pin the user on it. `_lastRatedRide` is what
      // stops that, and it survives the restore.
      final h = await start(tester, Role.passenger, '/p');
      final ride = app.rides.publishRide(
        buildFinishedRide(
          userId: app.session.requireUser.id,
          asDriver: false,
          status: RideStatus.completed,
          rated: false,
        ),
      );
      await settle(tester);
      expect(here(), '/rate/${ride.id}');

      expect(
        await pressBackUntilOut(tester, h),
        1,
        reason:
            'one press should leave the rating screen and empty the history. '
            'More than one, or null, means the home screen pushed it again.',
      );
      expect(here(), '/p');
    });

    testWidgets('on a cold load of a location the guard refuses', (
      tester,
    ) async {
      // A shared link into the driver home, opened by a passenger. The
      // redirect is right here — there is no history to walk back into, and
      // the entry it replaces is the empty one every app starts with.
      final h = await start(tester, Role.passenger, '/d');
      expect(here(), '/p');
      expect(
        h.length,
        1,
        reason: 'the first report of a session replaces rather than pushes',
      );
      expect(h.canGoBack, isFalse);
    });
  });

  group('KNOWN DEFECT: Back is dead after these, and these tests say so', () {
    // Read the assertions carefully: they assert the bug. Each one measures
    // that the history never drains, which is a dead Back button — press it
    // for ever and the page never changes.
    //
    // They are written this way because there is no fix available at this
    // layer, and a defect nobody can reproduce is a defect that gets argued
    // about. The mechanism:
    //
    //   Back pops its entry and hands the app that location. The guard
    //   refuses it and the app reports somewhere else. go_router reports a
    //   location change with `replace: false`, so the report is a pushState,
    //   and the stack ends the gesture as deep as it began.
    //
    // Three fixes were tried against this and measured, not reasoned about:
    //
    //   `context.replace()`  reports the same way `go` does. No effect.
    //   `routerNeglect: true`  makes every report a replace, so the history
    //                          never holds more than one entry and Back
    //                          leaves the app from everywhere — it would
    //                          break 'Back works', above.
    //   `onEnter`/`Block.stop()`  halts the navigation, but the provider has
    //                          already moved to the location Back supplied,
    //                          so the unchanged stack is re-synced as a
    //                          push. No effect. It only appeared to work
    //                          against entries carrying a null state, which
    //                          'an entry with no state' above now pins.
    //
    // go_router 18.1.0 changes nothing here either. What is left is a product
    // decision — whether a role home may be entered by whoever asks for it,
    // which would retire the guard that does the refusing — and that is the
    // user's to make, not this file's.
    //
    // **When one of these fails, the defect is fixed.** Delete the test and
    // put the journey in 'Back works' instead.
    testWidgets('after switching role', (tester) async {
      final h = await start(tester, Role.passenger, '/p');
      app.session.setRole(Role.driver);
      config.router.go('/d');
      await settle(tester);
      expect(h.length, 2);

      expect(
        await pressBackUntilOut(tester, h),
        isNull,
        reason:
            'FIXED? Back now leaves the app after a role switch. Delete this '
            'test and assert the drain in "Back works" instead.',
      );
      expect(here(), '/d', reason: 'and the screen never changed');
    });

    testWidgets('after signing in', (tester) async {
      final h = await start(tester, Role.passenger, '/intro', signedOut: true);
      config.router.go('/auth/phone');
      await settle(tester);
      config.router.push('/auth/otp', extra: '+60123456789');
      await settle(tester);
      config.router.push('/auth/profile', extra: ('+60123456789', null));
      await settle(tester);
      app.session.signIn('+60123456789', name: 'Nurul Ain binti Abdullah');
      config.router.go('/p');
      await settle(tester);
      expect(here(), '/p');
      expect(
        h.length,
        greaterThan(1),
        reason: 'the auth steps are behind us in the history',
      );

      expect(
        await pressBackUntilOut(tester, h),
        isNull,
        reason:
            'FIXED? Back now leaves the app after signing in. Delete this '
            'test and assert the drain in "Back works" instead.',
      );
      expect(here(), '/p', reason: 'and the screen never changed');
    });
  });
}

/// One browser history entry: the URL, and the state the app stored with it.
class Entry {
  Entry(this.uri, this.state);
  final String uri;
  final Object? state;
}

/// The browser's history stack, as the app can observe it.
///
/// Both directions of the real contract, and nothing else:
///
///   out  `SystemChannels.navigation` → `routeInformationUpdated`, carrying
///        `{uri, state, replace}`. `replace: false` is a `pushState` and adds
///        an entry; `replace: true` is a `replaceState` and overwrites the
///        top one. `selectSingleEntryHistory` switches to a mode where every
///        update overwrites, which go_router never selects — it calls
///        `selectMultiEntryHistory` before every report.
///
///   in   Back and Forward arrive as `pushRouteInformation` on the same
///        channel, carrying the popped entry's location and state. Note the
///        key is `location` going in and `uri` coming out; they are not the
///        same name.
///
/// What it leaves out: the origin entry and serial-count bookkeeping that
/// `MultiEntriesBrowserHistory` keeps for itself. None of it is observable
/// from inside the app, which is where the defect is.
class History {
  History(this._tester) {
    _tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        switch (call.method) {
          case 'selectMultiEntryHistory':
            _multiEntry = true;
          case 'selectSingleEntryHistory':
            _multiEntry = false;
          case 'routeInformationUpdated':
            final args = (call.arguments as Map).cast<String, Object?>();
            _record(
              Entry(args['uri'] as String, args['state']),
              replace: args['replace'] as bool? ?? false,
            );
        }
        return null;
      },
    );
    addTearDown(
      () => _tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      ),
    );
  }

  final WidgetTester _tester;
  final List<Entry> entries = [];
  bool _multiEntry = true;

  int get length => entries.length;
  String? get top => entries.isEmpty ? null : entries.last.uri;

  /// Whether a press of Back has an entry of this app's to land on. False
  /// means the next press leaves for whatever the browser showed before.
  bool get canGoBack => entries.length > 1;

  void _record(Entry entry, {required bool replace}) {
    if (entries.isEmpty) {
      entries.add(entry);
    } else if (replace || !_multiEntry) {
      entries[entries.length - 1] = entry;
    } else {
      entries.add(entry);
    }
  }

  /// Presses Back: pop the entry, then hand the app the one underneath.
  Future<void> back() async {
    entries.removeLast();
    final top = entries.last;
    await _tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(
        MethodCall('pushRouteInformation', <String, Object?>{
          'location': top.uri,
          'state': top.state,
        }),
      ),
      (_) {},
    );
  }

  /// For the harness's own tests: the outbound call, without an app.
  Future<void> pretendTheAppReported(
    String uri, {
    required bool replace,
  }) async {
    await SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(uri),
      state: const <String, Object?>{'stub': true},
      replace: replace,
    );
  }
}
