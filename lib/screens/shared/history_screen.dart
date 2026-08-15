import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Role? _role;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;
    final role = _role ??= session.prefs.role;

    final list = rides.historyFor(user.id, role);
    final grouped = <String, List<Ride>>{};
    for (final ride in list) {
      final key = dateLabel(
        ride.completedAt ?? ride.cancelledAt ?? ride.createdAt,
      );
      grouped.putIfAbsent(key, () => []).add(ride);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('My rides'),
      ),
      body: Column(
        children: [
          if (user.isDriver)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Segmented<Role>(
                value: role,
                onChanged: (v) => setState(() => _role = v),
                options: const [
                  (Role.passenger, 'As passenger'),
                  (Role.driver, 'As driver'),
                ],
              ),
            ),
          Expanded(
            child: grouped.isEmpty
                ? EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No rides yet',
                    body: role == Role.driver
                        ? 'Completed trips you drive will appear here.'
                        : 'Book your first ride and it will show up here.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      for (final entry in grouped.entries) ...[
                        SectionLabel(
                          entry.key,
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                        ),
                        for (final ride in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _HistoryCard(ride: ride, role: role),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.ride, required this.role});

  final Ride ride;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cancelled = ride.status == RideStatus.cancelled;
    final amount = role == Role.driver ? driverNet(ride.fare) : ride.fare;

    return AppCard(
      onTap: () => context.push('/ride/${ride.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      cancelled
                          ? Icons.cancel_outlined
                          : Icons.schedule_rounded,
                      size: 14,
                      color: cancelled ? c.danger : c.textDim,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        cancelled
                            ? 'Cancelled'
                            : '${clockTime(ride.completedAt ?? ride.createdAt)} · '
                                  '${distanceLabel(ride.distanceKm)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cancelled ? c.danger : c.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                money(amount, decimals: false),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cancelled ? c.textMute : c.text,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
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
          if (role == Role.passenger && ride.ratingByPassenger != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 13, color: c.accent),
                const SizedBox(width: 4),
                Text(
                  'You rated ${ride.ratingByPassenger!.stars}',
                  style: TextStyle(fontSize: 12, color: c.textMute),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
