import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/geo.dart';
import '../../core/storage.dart';
import '../../data/places.dart';
import '../../models/models.dart';
import '../../state/draft.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/map_view.dart';
import '../../widgets/passenger/idle_sheet.dart';
import '../../widgets/passenger/offers_sheet.dart';
import '../../widgets/passenger/price_sheet.dart';
import '../../widgets/passenger/tracking_sheet.dart';
import '../../widgets/ui.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  String? _lastRatedRide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedPickup());
  }

  void _seedPickup() {
    if (!mounted) return;
    final draft = context.read<DraftStore>();
    if (draft.pickup != null) return;
    final session = context.read<SessionStore>();
    draft.setPickup(
      Place(
        id: uid('pin'),
        name: 'Current location',
        address: streets[DateTime.now().microsecond % streets.length],
        coord: session.myLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final draft = context.watch<DraftStore>();
    final user = session.requireUser;

    final activeRide = rides.activeRideFor(user.id, Role.passenger);

    // A finished ride always leads to the rating screen.
    final toRate = rides.rideAwaitingRating(user.id, Role.passenger);
    if (toRate != null && toRate.id != _lastRatedRide) {
      _lastRatedRide = toRate.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/rate/${toRate.id}');
      });
    }

    // Publishing an order closes the composer.
    if (activeRide != null && draft.step != DraftStep.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) draft.setStep(DraftStep.idle);
      });
    }

    final drivers = activeRide?.driverId == null
        ? rides.nearbyDrivers.values.toList()
        : rides.nearbyDrivers.values
              .where((d) => d.id == activeRide!.driverId)
              .toList();

    final pins = <MapPin>[];
    if (activeRide != null) {
      pins.add(
        MapPin(
          'pickup',
          activeRide.pickup.coord,
          PinKind.pickup,
          label: 'Pickup',
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
    } else {
      if (draft.pickup != null) {
        pins.add(
          MapPin(
            'pickup',
            draft.pickup!.coord,
            PinKind.pickup,
            label: 'Pickup',
          ),
        );
      } else {
        pins.add(MapPin('me', session.myLocation, PinKind.me));
      }
      if (draft.stop != null) {
        pins.add(MapPin('stop', draft.stop!.coord, PinKind.stop));
      }
      if (draft.dropoff != null) {
        pins.add(
          MapPin(
            'dropoff',
            draft.dropoff!.coord,
            PinKind.dropoff,
            label: draft.dropoff!.name,
          ),
        );
      }
    }

    final route = activeRide != null
        ? (activeRide.status == RideStatus.inProgress ||
                  activeRide.status == RideStatus.searching
              ? activeRide.routeGeometry
              : null)
        : (draft.pickup != null && draft.dropoff != null
              ? syntheticRoute(draft.pickup!.coord, draft.dropoff!.coord, 3)
              : null);

    // Dashed line from the driver's live position to where they're headed.
    final approach =
        (activeRide?.driverCoord != null &&
            (activeRide!.status == RideStatus.accepted ||
                activeRide.status == RideStatus.arriving))
        ? syntheticRoute(activeRide.driverCoord!, activeRide.pickup.coord, 1)
        : null;

    final fitToken = activeRide != null
        ? '${activeRide.id}:${activeRide.status.name}'
        : (draft.pickup != null && draft.dropoff != null
              ? 'draft:${draft.pickup!.id}:${draft.dropoff!.id}'
              : null);

    final sheetHeight = activeRide != null
        ? 360.0
        : (draft.step == DraftStep.price ? 430.0 : 300.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapView(
              center: session.myLocation,
              pins: pins,
              drivers: drivers,
              route: route,
              approach: approach,
              fitToken: fitToken,
              bottomPadding: sheetHeight,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FabButton(
                    icon: Icons.menu_rounded,
                    tooltip: 'Menu',
                    onTap: () => context.push('/menu'),
                  ),
                  const Spacer(),
                  if (user.isDriver && activeRide == null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _RoleSwitch(
                        icon: Icons.directions_car_filled_rounded,
                        label: 'Drive',
                        onTap: () {
                          session.setRole(Role.driver);
                          context.go('/d');
                        },
                      ),
                    ),
                  FabButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
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
                ? (activeRide.status == RideStatus.searching
                      ? OffersSheet(ride: activeRide)
                      : TrackingSheet(ride: activeRide))
                : (draft.step == DraftStep.price && draft.dropoff != null
                      ? const PriceSheet()
                      : const IdleSheet()),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
