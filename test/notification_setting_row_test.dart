import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/notifier.dart';
import 'package:get_teksi/l10n/app_localizations.dart';
import 'package:get_teksi/models/models.dart';
import 'package:get_teksi/theme.dart';
import 'package:get_teksi/widgets/notification_setting_row.dart';
import 'package:provider/provider.dart';

/// The way back in after saying no.
///
/// Every platform asks for this permission once and then stops: Android will
/// not show the prompt again after a refusal, iOS never shows it twice, and a
/// browser remembers a denial for the origin. So one reflexive dismissal —
/// from a dialog that appears before the app has shown why it wants one — used
/// to turn the whole notification feature off for good, with nothing anywhere
/// in the app to say so or undo it.
///
/// These are about what the row does with each answer, which is the part that
/// has to be right before any of it is worth showing.

/// A notifier a test can steer, and which records what was asked of it.
class _FakeNotifier implements Notifier {
  _FakeNotifier(this._status);

  NotificationPermission _status;

  /// Whether granting happens when asked. False models a platform that has
  /// stopped offering the prompt: the call returns, and nothing changes.
  bool grantsOnRequest = false;

  /// Whether there is a settings screen to send anyone to. False is a browser.
  bool canOpenSettings = true;

  final List<String> calls = [];

  @override
  Future<void> requestPermission() async {
    calls.add('request');
    if (grantsOnRequest) _status = NotificationPermission.granted;
  }

  @override
  Future<NotificationPermission> status() async => _status;

  @override
  Future<bool> openSettings() async {
    calls.add('openSettings');
    return canOpenSettings;
  }

  @override
  Future<void> show(AppNotification notification, {bool sound = true}) async {}
}

void main() {
  /// The row, with everything it reads from the tree and nothing else.
  Future<void> pump(WidgetTester tester, _FakeNotifier notifier) async {
    await tester.pumpWidget(
      Provider<Notifier>.value(
        value: notifier,
        child: MaterialApp(
          theme: buildTheme(dark: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Column(children: [NotificationSettingRow()]),
          ),
        ),
      ),
    );
    // One for the first frame, one for the status the row asks for on start.
    await tester.pumpAndSettle();
  }

  testWidgets('a granted permission reads as on', (tester) async {
    await pump(tester, _FakeNotifier(NotificationPermission.granted));

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
  });

  testWidgets('a refusal offers a way to undo itself', (tester) async {
    // The state the app used to have no answer for at all.
    await pump(tester, _FakeNotifier(NotificationPermission.denied));

    expect(find.text('Off — tap to turn them on'), findsOneWidget);
  });

  testWidgets('tapping asks, and stops there when that works', (tester) async {
    // The first tap on a platform that still has a prompt to show. Sending
    // someone on to the system settings screen after they have just granted it
    // would be a second thing to do for a job already done.
    final notifier = _FakeNotifier(NotificationPermission.denied)
      ..grantsOnRequest = true;
    await pump(tester, notifier);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(notifier.calls, ['request']);
    expect(find.text('On'), findsOneWidget);
  });

  testWidgets('a spent prompt falls through to system settings', (
    tester,
  ) async {
    // The case that matters. Asking again does nothing and says nothing, so
    // the row has to carry on to where the answer actually lives — otherwise
    // it is a control that looks like a control and is not one.
    final notifier = _FakeNotifier(NotificationPermission.denied);
    await pump(tester, notifier);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(notifier.calls, ['request', 'openSettings']);
  });

  testWidgets('an already-granted row goes straight to settings', (
    tester,
  ) async {
    // Tapping a row that says "On" means wanting it off, and off lives in the
    // same place. Asking for a permission already held would do nothing.
    final notifier = _FakeNotifier(NotificationPermission.granted);
    await pump(tester, notifier);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(notifier.calls, ['openSettings']);
  });

  testWidgets('nowhere to send anyone is said out loud', (tester) async {
    // A browser: the permission lives in chrome no page may open. A tap that
    // silently did nothing would read as a broken row.
    final notifier = _FakeNotifier(NotificationPermission.denied)
      ..canOpenSettings = false;
    await pump(tester, notifier);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('a platform with no notifications is not a broken row', (
    tester,
  ) async {
    final notifier = _FakeNotifier(NotificationPermission.unavailable);
    await pump(tester, notifier);

    expect(find.text('Not available on this device'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    // Nothing was asked of a platform that has nothing to ask.
    expect(notifier.calls, isEmpty);
  });

  testWidgets('coming back from settings re-reads the answer', (tester) async {
    // The answer changes somewhere this app cannot see. Without the lifecycle
    // observer the row still reads "Off" after the user has just switched it
    // on, which is the moment they look at it to check.
    final notifier = _FakeNotifier(NotificationPermission.denied);
    await pump(tester, notifier);
    expect(find.text('Off — tap to turn them on'), findsOneWidget);

    notifier._status = NotificationPermission.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('On'), findsOneWidget);
  });
}
