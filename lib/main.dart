import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/backend.dart';
import 'core/duty.dart';
import 'core/location.dart';
import 'core/notifier.dart';
import 'core/storage.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'services/driver_beacon.dart';
import 'services/duty_presence.dart';
import 'services/profile_sync.dart';
import 'services/simulation.dart';
import 'state/draft.dart';
import 'state/rides.dart';
import 'state/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  // Connects to the backend if one is configured at build time, and otherwise
  // leaves the app on its on-device transport. Never throws: a backend that is
  // unreachable degrades to the local marketplace rather than a blank screen.
  await Backend.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const GetTeksiApp());
}

/// One notifier for the process. Built here rather than per-store because the
/// platform plugin is a singleton behind it either way, and a second one would
/// only re-initialise the same channel.
final Notifier _notifier = createNotifier();

/// One duty service for the process, for the same reason: there is a single
/// Android service behind it either way.
final DutyService _dutyService = createDutyService();

class GetTeksiApp extends StatelessWidget {
  const GetTeksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // Asks the platform where we are, and carries on from the city
          // centre if it will not say — declined permission, location off, or
          // no fix. locate() is fire-and-forget for exactly that reason.
          create: (_) =>
              SessionStore(location: const DeviceLocationService())..locate(),
        ),
        ChangeNotifierProxyProvider<SessionStore, RidesStore>(
          create: (context) => RidesStore(
            context.read<SessionStore>(),
            // Puts what the bell records in front of someone who is not
            // looking at the app.
            onAlert: (n) => unawaited(_notifier.show(n)),
            // With a backend the database settles rides itself, so the client
            // must not also write its own wallet entries.
            settlesRemotely: Backend.isLive,
          ),
          update: (_, _, rides) => rides!,
        ),
        ChangeNotifierProvider(create: (_) => DraftStore()),
      ],
      child: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final GoRouterConfig _routerConfig;
  MarketplaceSimulation? _simulation;
  DriverBeacon? _beacon;
  ProfileSync? _profileSync;
  DutyPresence? _duty;
  bool _askedToNotify = false;

  @override
  void initState() {
    super.initState();
    _routerConfig = GoRouterConfig(context.read<SessionStore>());
  }

  @override
  void dispose() {
    _simulation?.dispose();
    _beacon?.dispose();
    _profileSync?.dispose();
    final duty = _duty;
    if (duty != null) unawaited(duty.dispose());
    _routerConfig.dispose();
    super.dispose();
  }

  /// The bot marketplace runs only while signed in and enabled in settings.
  void _syncSimulation(SessionStore session, RidesStore rides) {
    final wanted = session.user != null && session.prefs.simulationEnabled;
    final sim = _simulation ??= MarketplaceSimulation(session, rides);
    if (wanted && !sim.isRunning) {
      sim.start();
    } else if (!wanted && sim.isRunning) {
      sim.stop();
    }
  }

  /// Asks for the notification permission once, after there is a reason to.
  ///
  /// Not at startup: a permission dialog on first launch, before the app has
  /// shown what it does, is the one people refuse out of hand. By the time
  /// someone has signed in they have a ride to be told about.
  void _askToNotify(SessionStore session) {
    if (_askedToNotify || session.user == null) return;
    _askedToNotify = true;
    unawaited(_notifier.requestPermission());
  }

  /// Keeps the server's copy of the profile in step with this device's.
  ///
  /// Runs for any signed-in user against a real backend, not just drivers: the
  /// name and colour a passenger picks are what a driver sees on the order
  /// card, and they reach the server the same way.
  void _syncProfile(SessionStore session) {
    final wanted = Backend.isLive && session.user != null;
    final sync = _profileSync ??= ProfileSync(
      session,
      push: Backend.saveProfile,
    );
    if (wanted && !sync.isRunning) {
      sync.start();
    } else if (!wanted && sync.isRunning) {
      sync.stop();
    }
  }

  /// The position beacon runs only for a real driver who is on duty against a
  /// real backend.
  ///
  /// Without a backend there is nobody to tell: the only other participants are
  /// bots in this same process, which read the store directly. Off duty it
  /// stays stopped, because a driver who is not working has not agreed to be
  /// followed — going offline is the control that has to actually stop the
  /// reporting, not merely hide the car.
  void _syncBeacon(SessionStore session, RidesStore rides) {
    final wanted = Backend.isLive && session.isDriverOnDuty;
    final beacon = _beacon ??= DriverBeacon(session, rides);
    if (wanted && !beacon.isRunning) {
      beacon.start();
    } else if (!wanted && beacon.isRunning) {
      beacon.stop();
    }
  }

  /// Asks Android to keep the process alive while a driver is on duty.
  ///
  /// The same condition as the beacon, because it exists for the beacon: a
  /// frozen process reports no position, and a driver who switched to Waze has
  /// backgrounded this app by definition. The strings come from here rather
  /// than from the Kotlin so the driver's own language reaches the one
  /// notification they will be looking at all evening.
  void _syncDuty(SessionStore session, AppLocalizations l) {
    final duty = _duty ??= DutyPresence(
      session,
      service: _dutyService,
      backendLive: Backend.isLive,
    );
    unawaited(
      duty.sync(title: l.dutyNotificationTitle, body: l.dutyNotificationBody),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final rides = context.read<RidesStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncSimulation(session, rides);
        _syncBeacon(session, rides);
        _syncProfile(session);
        _askToNotify(session);
      }
    });

    return MaterialApp.router(
      title: 'GET.teksi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark: false),
      darkTheme: buildTheme(dark: true),
      themeMode: session.prefs.darkTheme ? ThemeMode.dark : ThemeMode.light,
      // The Language setting drives this. A key with no Malay entry falls back
      // to the English template, so a screen that has not been translated yet
      // stays readable rather than showing a key or throwing.
      locale: Locale(session.prefs.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _routerConfig.router,
      builder: (context, child) {
        // The one context below MaterialApp's Localizations, and so the only
        // place the duty notification's own words can be read. Doing it here
        // also means a language change reaches the notification: this rebuilds
        // when the locale does.
        final l = AppLocalizations.of(context);
        if (l != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncDuty(session, l);
          });
        }

        // The UI is designed as a phone-shaped column; on desktop and wide
        // web it stays centred at phone width rather than stretching.
        return Container(
          color: Colors.black,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
