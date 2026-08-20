import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/backend.dart';
import 'core/location.dart';
import 'core/storage.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
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

  @override
  void initState() {
    super.initState();
    _routerConfig = GoRouterConfig(context.read<SessionStore>());
  }

  @override
  void dispose() {
    _simulation?.dispose();
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final rides = context.read<RidesStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSimulation(session, rides);
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
