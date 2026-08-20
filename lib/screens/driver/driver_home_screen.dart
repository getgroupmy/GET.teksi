import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/driver/active_ride_sheet.dart';
import '../../widgets/driver/order_feed_sheet.dart';
import '../../widgets/map_view.dart';
import '../../widgets/ui.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String? _lastRatedRide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    // A driver without a vehicle on file has to finish onboarding first.
    if (!user.isDriver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/d/onboarding');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final activeRide = rides.activeRideFor(user.id, Role.driver);

    final toRate = rides.rideAwaitingRating(user.id, Role.driver);
    if (toRate != null && toRate.id != _lastRatedRide) {
      _lastRatedRide = toRate.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/rate/${toRate.id}');
      });
    }

    final pins = <MapPin>[MapPin('me', session.myLocation, PinKind.me)];
    if (activeRide != null) {
      pins.add(
        MapPin(
          'pickup',
          activeRide.pickup.coord,
          PinKind.pickup,
          label: activeRide.pickup.name,
        ),
      );
      if (activeRide.stop != null) {
        pins.add(MapPin('stop', activeRide.stop!.coord, PinKind.stop));
      }
      pins.add(
        MapPin(
          'dropoff',
          activeRide.dropoff.coord,
          PinKind.dropoff,
          label: activeRide.dropoff.name,
        ),
      );
    }

    final route = activeRide == null
        ? null
        : (activeRide.status == RideStatus.inProgress
              ? (activeRide.routeGeometry ??
                    syntheticRoute(
                      activeRide.pickup.coord,
                      activeRide.dropoff.coord,
                      3,
                    ))
              : syntheticRoute(session.myLocation, activeRide.pickup.coord, 1));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapView(
              center: session.myLocation,
              pins: pins,
              route: route,
              fitToken: activeRide == null
                  ? null
                  : '${activeRide.id}:${activeRide.status.name}',
              bottomPadding: activeRide != null ? 400 : 340,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FabButton(
                    icon: Icons.menu_rounded,
                    tooltip: l.menu,
                    onTap: () => context.push('/menu'),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: l.earningsSemantics(
                      money(user.driverProfile!.earnings),
                      session.prefs.driverOnline ? l.onlineWord : l.offlineWord,
                    ),
                    child: Material(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(999),
                      elevation: 4,
                      shadowColor: Colors.black54,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => context.push('/d/earnings'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: c.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 15,
                                color: c.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                money(
                                  user.driverProfile!.earnings,
                                  decimals: false,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Colour alone must not carry the duty state.
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: session.prefs.driverOnline
                                      ? c.ok
                                      : c.textMute,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                session.prefs.driverOnline ? l.on : l.off,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: session.prefs.driverOnline
                                      ? c.ok
                                      : c.textMute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (activeRide == null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FabButton(
                        icon: Icons.person_outline_rounded,
                        tooltip: l.switchToPassengerTooltip,
                        onTap: () {
                          session.setRole(Role.passenger);
                          context.go('/p');
                        },
                      ),
                    ),
                  FabButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: l.notifications,
                    badge: rides.unreadNotifications,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: activeRide != null
                ? ActiveRideSheet(
                    ride: activeRide,
                    driverAt: session.myLocation,
                  )
                : OrderFeedSheet(driverAt: session.myLocation),
          ),
        ],
      ),
    );
  }
}
