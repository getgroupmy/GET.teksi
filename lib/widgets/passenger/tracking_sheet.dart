import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../data/fixtures.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../ui.dart';

const _copy = <RideStatus, (String, String)>{
  RideStatus.accepted: ('Driver is on the way', 'Meet your driver at the pickup point'),
  RideStatus.arriving: ('Driver is arriving', 'Please start heading to the pickup point'),
  RideStatus.waiting: ('Your driver is waiting', 'They can wait a few minutes free of charge'),
  RideStatus.inProgress: ('On the way to your destination', 'Enjoy the ride'),
};

class TrackingSheet extends StatelessWidget {
  const TrackingSheet({super.key, required this.ride});

  final Ride ride;

  String get _shareText =>
      "I'm on a GET.teksi ride to ${ride.dropoff.name}. "
      'Driver: ${ride.driverName} (${ride.driverVehicle?.describe}, '
      '${ride.driverVehicle?.plate}). '
      'Ref ${ride.id.substring(ride.id.length - 6).toUpperCase()}.';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rides = context.watch<RidesStore>();
    final unread = rides.unreadChat(ride.id, Role.passenger);
    final (title, sub) = _copy[ride.status] ?? _copy[RideStatus.accepted]!;

    final target = ride.status == RideStatus.inProgress
        ? ride.dropoff.coord
        : ride.pickup.coord;
    final eta = ride.driverCoord == null
        ? ride.durationMinutes
        : driveMinutes(haversineKm(ride.driverCoord!, target) * 1.35);

    return MapSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (ride.status != RideStatus.waiting)
                Text(
                  durationLabel(eta),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 13, color: c.textDim)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Avatar(
                  name: ride.driverName ?? '',
                  color: ride.driverAvatarColor ?? 0xFF9AA39D,
                  size: 46,
                  ring: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.driverName ?? 'Driver',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RatingChip(value: ride.driverRating ?? 5),
                        ],
                      ),
                      if (ride.driverVehicle != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.directions_car_rounded, size: 13, color: c.textDim),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ride.driverVehicle!.describe,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.5, color: c.textDim),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    ride.driverVehicle?.plate ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                onTap: () => _snack(context, 'Calling ${ride.driverName}…'),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () => _share(context),
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
                      ride.paymentMethod == PaymentMethod.cash
                          ? 'Pay in cash'
                          : ride.paymentMethod.label,
                      style: TextStyle(fontSize: 13, color: c.textDim),
                    ),
                    Text(
                      money(ride.fare, decimals: false),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ride.status == RideStatus.waiting) ...[
            const SizedBox(height: 12),
            const InfoBanner(
              'Your driver has arrived. Free waiting time applies for 3 minutes.',
              tone: BannerTone.warn,
            ),
          ],

          if (ride.status != RideStatus.inProgress) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _confirmCancel(context, context.read<RidesStore>()),
                style: TextButton.styleFrom(
                  backgroundColor: c.danger.withValues(alpha: 0.14),
                  foregroundColor: c.danger,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel ride'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _shareText));
    showAppSheet(
      context,
      title: 'Share your trip',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send these details to someone you trust — they’re already on your clipboard.',
            style: TextStyle(fontSize: 13.5, color: sheetContext.c.textDim),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sheetContext.c.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_shareText, style: const TextStyle(fontSize: 13.5, height: 1.45)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, RidesStore rides) {
    showAppSheet(
      context,
      title: 'Cancel this ride?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoBanner(
            'Your driver is already on the way. Frequent late cancellations can affect your rating.',
            tone: BannerTone.warn,
          ),
          const SizedBox(height: 12),
          reasonList(sheetContext, cancelReasonsPassenger, (reason) {
            rides.cancelRide(ride.id, CancelledBy.passenger, reason);
            Navigator.of(sheetContext).pop();
          }),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Keep my ride'),
          ),
        ],
      ),
    );
  }
}
