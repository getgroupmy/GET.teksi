import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../data/fixtures.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../ui.dart';

/// The driver's job card. One primary button always drives the trip forward:
/// on my way → arrived → start → finish.
class ActiveRideSheet extends StatelessWidget {
  const ActiveRideSheet({super.key, required this.ride, required this.driverAt});

  final Ride ride;
  final LatLng driverAt;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rides = context.watch<RidesStore>();
    final unread = rides.unreadChat(ride.id, Role.driver);

    final heading = ride.status == RideStatus.inProgress ? ride.dropoff : ride.pickup;
    final km = haversineKm(driverAt, heading.coord) * 1.35;
    final eta = driveMinutes(km);

    final (primaryLabel, primaryAction) = switch (ride.status) {
      RideStatus.accepted || RideStatus.arriving => (
          "I've arrived",
          () => rides.setRideStatus(ride.id, RideStatus.waiting),
        ),
      RideStatus.waiting => (
          'Start the trip',
          () => rides.setRideStatus(ride.id, RideStatus.inProgress),
        ),
      RideStatus.inProgress => (
          'Finish trip · ${money(ride.fare, decimals: false)}',
          () => rides.completeRide(ride.id),
        ),
      _ => (null, null),
    };

    final title = switch (ride.status) {
      RideStatus.inProgress => 'To ${ride.dropoff.name}',
      RideStatus.waiting => 'Waiting for the passenger',
      _ => 'Pick up ${ride.passengerName}',
    };

    return MapSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${durationLabel(eta)} · ${distanceLabel(km)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.brand),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Avatar(name: ride.passengerName, color: ride.passengerAvatarColor, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.passengerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RatingChip(value: ride.passengerRating),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plural(ride.passengerCount, 'passenger')} · '
                        '${ride.paymentMethod == PaymentMethod.cash ? 'Cash' : ride.paymentMethod == PaymentMethod.card ? 'Card' : 'Wallet'}',
                        style: TextStyle(fontSize: 12.5, color: c.textDim),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(ride.fare, decimals: false),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'you get ${money(driverNet(ride.fare), decimals: false)}',
                      style: TextStyle(fontSize: 11, color: c.textDim),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ride.comment != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 15, color: c.textDim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.comment!,
                      style: TextStyle(fontSize: 13, color: c.textDim, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              ActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                badge: unread,
                onTap: () => context.push('/chat/${ride.id}'),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.phone_rounded,
                label: 'Call',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${ride.passengerName}…')),
                ),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.navigation_rounded,
                label: 'Navigate',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigating to ${heading.name}…')),
                ),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.shield_outlined,
                label: 'Safety',
                danger: true,
                onTap: () => context.push('/safety', extra: ride.id),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                RouteStops(
                  pickup: ride.pickup.name,
                  dropoff: ride.dropoff.name,
                  stop: ride.stop?.name,
                  compact: true,
                ),
                Divider(height: 24, color: c.line),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trip ${distanceLabel(ride.distanceKm)} · ${durationLabel(ride.durationMinutes)}',
                      style: TextStyle(fontSize: 12.5, color: c.textDim),
                    ),
                    Text(
                      'Fee ${money(commissionOn(ride.fare))}',
                      style: TextStyle(fontSize: 12.5, color: c.textDim),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ride.status == RideStatus.waiting) ...[
            const SizedBox(height: 12),
            const InfoBanner(
              'Free waiting time is 3 minutes. Message the passenger if they’re not out yet.',
            ),
          ],

          const SizedBox(height: 14),
          if (primaryLabel != null)
            FilledButton(onPressed: primaryAction, child: Text(primaryLabel)),
          if (ride.status != RideStatus.inProgress)
            TextButton(
              onPressed: () => _confirmCancel(context, rides),
              child: Text('Cancel this order', style: TextStyle(color: c.danger)),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, RidesStore rides) {
    showAppSheet(
      context,
      title: 'Cancel the order?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoBanner(
            'Cancelling accepted orders too often lowers your priority in the feed.',
            tone: BannerTone.warn,
          ),
          const SizedBox(height: 12),
          reasonList(sheetContext, cancelReasonsDriver, (reason) {
            rides.cancelRide(ride.id, CancelledBy.driver, reason);
            Navigator.of(sheetContext).pop();
          }),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Keep the order'),
          ),
        ],
      ),
    );
  }
}
