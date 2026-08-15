import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../ui.dart';

enum _SortMode { nearest, highest, newest }

class OrderFeedSheet extends StatefulWidget {
  const OrderFeedSheet({super.key, required this.driverAt});

  final LatLng driverAt;

  @override
  State<OrderFeedSheet> createState() => _OrderFeedSheetState();
}

class _OrderFeedSheetState extends State<OrderFeedSheet> {
  _SortMode _sort = _SortMode.nearest;
  int _minFare = 0;
  double _maxPickupKm = 12;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    if (!session.prefs.driverOnline) {
      return MapSheet(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                size: 28,
                color: c.textDim,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'You’re offline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Go online to see ride requests near you and send your price.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: c.textDim, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  session.setPrefs(session.prefs.copyWith(driverOnline: true)),
              child: const Text('Go online'),
            ),
            TextButton(
              onPressed: () => context.push('/d/earnings'),
              child: Text(
                'View today’s earnings',
                style: TextStyle(color: c.textDim),
              ),
            ),
          ],
        ),
      );
    }

    final pending = rides.pendingOfferRideIds(user.id);
    final decorated =
        rides
            .openOrders(user.id)
            .map((ride) {
              final pickupKm =
                  haversineKm(widget.driverAt, ride.pickup.coord) * 1.35;
              return (
                ride: ride,
                pickupKm: pickupKm,
                eta: driveMinutes(pickupKm),
              );
            })
            .where(
              (o) =>
                  o.pickupKm <= _maxPickupKm && o.ride.askingPrice >= _minFare,
            )
            .toList()
          ..sort(
            (a, b) => switch (_sort) {
              _SortMode.nearest => a.pickupKm.compareTo(b.pickupKm),
              _SortMode.highest => b.ride.askingPrice.compareTo(
                a.ride.askingPrice,
              ),
              _SortMode.newest => b.ride.createdAt.compareTo(a.ride.createdAt),
            },
          );

    return MapSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      decorated.isEmpty
                          ? 'Waiting for orders'
                          : '${plural(decorated.length, 'order')} nearby',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'You’re online · ${user.driverProfile?.vehicle.plate ?? ''}',
                      style: TextStyle(fontSize: 12.5, color: c.textDim),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 18),
                tooltip: 'Filters',
                onPressed: () => _showFilters(context),
                style: IconButton.styleFrom(backgroundColor: c.surface3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Segmented<_SortMode>(
            value: _sort,
            onChanged: (v) => setState(() => _sort = v),
            options: const [
              (_SortMode.nearest, 'Nearest'),
              (_SortMode.highest, 'Highest'),
              (_SortMode.newest, 'Newest'),
            ],
          ),
          const SizedBox(height: 12),
          if (decorated.isEmpty) ...[
            const RadarBar(),
            const EmptyState(
              icon: Icons.inbox_rounded,
              title: 'No orders match right now',
              body: 'Stay online — new requests appear here as passengers publish them.',
            ),
          ] else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 330),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: decorated.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = decorated[i];
                  return _OrderCard(
                    ride: item.ride,
                    pickupKm: item.pickupKm,
                    pickupEta: item.eta,
                    pending: pending.contains(item.ride.id),
                    onTap: () => context.push('/d/order/${item.ride.id}'),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                session.setPrefs(session.prefs.copyWith(driverOnline: false)),
            icon: const Icon(Icons.power_settings_new_rounded, size: 17),
            label: const Text('Go offline'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.text,
              side: BorderSide(color: c.line),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showAppSheet(
      context,
      title: 'Filter orders',
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(
              'Minimum fare',
              padding: EdgeInsets.only(bottom: 8),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final v in [0, 1000, 1500, 2500])
                  AppChip(
                    label: v == 0 ? 'Any' : money(v, decimals: false),
                    selected: _minFare == v,
                    onTap: () {
                      setState(() => _minFare = v);
                      setSheetState(() {});
                    },
                  ),
              ],
            ),
            const SectionLabel(
              'Maximum distance to pickup',
              padding: EdgeInsets.only(top: 20, bottom: 8),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final v in [3.0, 6.0, 12.0, 30.0])
                  AppChip(
                    label: '${v.round()} km',
                    selected: _maxPickupKm == v,
                    onTap: () {
                      setState(() => _maxPickupKm = v);
                      setSheetState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.ride,
    required this.pickupKm,
    required this.pickupEta,
    required this.pending,
    required this.onTap,
  });

  final Ride ride;
  final double pickupKm;
  final int pickupEta;
  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final generous = ride.askingPrice >= ride.recommendedPrice;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pending
                ? c.warn.withValues(alpha: 0.45)
                : (generous ? c.brand.withValues(alpha: 0.35) : c.line),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  name: ride.passengerName,
                  color: ride.passengerAvatarColor,
                  size: 34,
                ),
                const SizedBox(width: 10),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          RatingChip(value: ride.passengerRating, size: 12),
                        ],
                      ),
                      Text(
                        timeAgo(ride.createdAt),
                        style: TextStyle(fontSize: 11.5, color: c.textMute),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(ride.askingPrice, decimals: false),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'net ${money(driverNet(ride.askingPrice), decimals: false)}',
                      style: TextStyle(fontSize: 11, color: c.textDim),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            RouteStops(
              pickup: ride.pickup.name,
              dropoff: ride.dropoff.name,
              stop: ride.stop?.name,
              compact: true,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${distanceLabel(pickupKm)} to pickup · ${durationLabel(pickupEta)}',
                  style: TextStyle(fontSize: 12, color: c.textDim),
                ),
                Text(
                  'Trip ${distanceLabel(ride.distanceKm)}',
                  style: TextStyle(fontSize: 12, color: c.textDim),
                ),
              ],
            ),
            if (pending) ...[
              const SizedBox(height: 8),
              Text(
                'Your offer is waiting for a reply',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.warn,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
