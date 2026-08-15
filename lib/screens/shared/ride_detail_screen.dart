import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/map_view.dart';
import '../../widgets/ui.dart';

class RideDetailScreen extends StatelessWidget {
  const RideDetailScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final ride = rides.rides[rideId];

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Trip details'),
        ),
        body: const EmptyState(title: 'Ride not found'),
      );
    }

    final asDriver = ride.driverId == session.requireUser.id;
    final net = driverNet(ride.fare);
    final cancelled = ride.status == RideStatus.cancelled;
    final reference = ride.id.substring(ride.id.length - 8).toUpperCase();

    final other = asDriver
        ? (ride.passengerName, ride.passengerAvatarColor, ride.passengerRating)
        : (
            ride.driverName ?? 'Driver',
            ride.driverAvatarColor ?? 0xFF9AA39D,
            ride.driverRating ?? 5.0,
          );

    final pins = <MapPin>[
      MapPin('pickup', ride.pickup.coord, PinKind.pickup),
      if (ride.stop != null) MapPin('stop', ride.stop!.coord, PinKind.stop),
      MapPin('dropoff', ride.dropoff.coord, PinKind.dropoff),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trip details'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SizedBox(
            height: 190,
            child: MapView(
              center: ride.pickup.coord,
              pins: pins,
              route: ride.routeGeometry,
              fitToken: 'detail:${ride.id}',
              interactive: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        money(asDriver ? net : ride.fare),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${dateLabel(ride.completedAt ?? ride.createdAt)} · '
                      '${clockTime(ride.completedAt ?? ride.createdAt)}',
                      style: TextStyle(fontSize: 13, color: c.textDim),
                    ),
                  ],
                ),
                if (cancelled) ...[
                  const SizedBox(height: 12),
                  InfoBanner(
                    'Cancelled by ${switch (ride.cancelledBy) {
                      CancelledBy.driver => 'the driver',
                      CancelledBy.system => 'the system',
                      _ => 'you',
                    }}'
                    '${ride.cancelReason != null ? ' — ${ride.cancelReason}' : ''}.',
                    tone: BannerTone.danger,
                  ),
                ],
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      RouteStops(
                        pickup: ride.pickup.name,
                        dropoff: ride.dropoff.name,
                        stop: ride.stop?.name,
                      ),
                      Divider(height: 24, color: c.line),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            distanceLabel(ride.distanceKm),
                            style: TextStyle(fontSize: 13, color: c.textDim),
                          ),
                          Text(
                            durationLabel(ride.durationMinutes),
                            style: TextStyle(fontSize: 13, color: c.textDim),
                          ),
                          Text(
                            'Ref $reference',
                            style: TextStyle(fontSize: 13, color: c.textDim),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!cancelled) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: [
                        const SectionLabel(
                          'Fare breakdown',
                          padding: EdgeInsets.only(bottom: 10),
                        ),
                        _Line(label: 'Agreed price', value: money(ride.fare)),
                        if (ride.askingPrice != ride.fare)
                          _Line(
                            label: 'Your original offer',
                            value: money(ride.askingPrice),
                            muted: true,
                          ),
                        if (ride.priceRaises > 0)
                          _Line(
                            label: 'Price raised ${ride.priceRaises}×',
                            value: '',
                            muted: true,
                          ),
                        if (asDriver) ...[
                          _Line(
                            label: 'Service fee',
                            value: '−${money(commissionOn(ride.fare))}',
                            muted: true,
                          ),
                          Divider(height: 18, color: c.line),
                          _Line(label: 'You earned', value: money(net), bold: true),
                        ] else ...[
                          if (ride.tip != null && ride.tip! > 0)
                            _Line(label: 'Tip', value: money(ride.tip!)),
                          Divider(height: 18, color: c.line),
                          _Line(
                            label: 'Total paid',
                            value: money(ride.fare + (ride.tip ?? 0)),
                            bold: true,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Paid by ${switch (ride.paymentMethod) {
                                PaymentMethod.cash => 'cash',
                                PaymentMethod.card => 'card ···4821',
                                PaymentMethod.wallet => 'wallet',
                              }}',
                              style: TextStyle(fontSize: 12, color: c.textMute),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Avatar(name: other.$1, color: other.$2, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              other.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                RatingChip(value: other.$3),
                                if (!asDriver && ride.driverVehicle != null) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      ride.driverVehicle!.plate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.5, color: c.textDim),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (_) {
                  final mine = asDriver ? ride.ratingByDriver : ride.ratingByPassenger;
                  if (mine == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel(
                            'Your rating',
                            padding: EdgeInsets.only(bottom: 8),
                          ),
                          Row(
                            children: [
                              for (var n = 1; n <= 5; n++)
                                Icon(
                                  n <= mine.stars
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 18,
                                  color: n <= mine.stars ? c.accent : c.surface3,
                                ),
                            ],
                          ),
                          if (mine.tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final tag in mine.tags)
                                  AppChip(label: tag, selected: false, onTap: () {}),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: reference));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trip reference copied')),
                      );
                    },
                    child: const Text('Copy trip reference'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.muted = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = muted ? c.textDim : c.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
