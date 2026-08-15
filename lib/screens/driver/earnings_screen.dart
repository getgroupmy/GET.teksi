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

enum _Period { today, week, all }

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  _Period _period = _Period.today;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    final now = DateTime.now();
    final cutoff = switch (_period) {
      _Period.today => DateTime(now.year, now.month, now.day),
      _Period.week => now.subtract(const Duration(days: 7)),
      _Period.all => DateTime.fromMillisecondsSinceEpoch(0),
    };

    final trips = rides
        .historyFor(user.id, Role.driver)
        .where((r) => r.status == RideStatus.completed)
        .where((r) => (r.completedAt ?? r.createdAt).isAfter(cutoff))
        .toList();

    final gross = trips.fold(0, (sum, r) => sum + r.fare);
    final net = trips.fold(0, (sum, r) => sum + driverNet(r.fare));
    final km = trips.fold(0.0, (sum, r) => sum + r.distanceKm);
    final minutes = trips.fold(0, (sum, r) => sum + r.durationMinutes);
    final rated = trips.where((r) => r.ratingByPassenger != null).toList();
    final avgRating = rated.isEmpty
        ? (user.driverProfile?.rating ?? 5)
        : rated.fold(0, (sum, r) => sum + r.ratingByPassenger!.stars) / rated.length;

    final grouped = <String, List<Ride>>{};
    for (final ride in trips) {
      final key = dateLabel(ride.completedAt ?? ride.createdAt);
      grouped.putIfAbsent(key, () => []).add(ride);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Earnings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Segmented<_Period>(
            value: _period,
            onChanged: (v) => setState(() => _period = v),
            options: const [
              (_Period.today, 'Today'),
              (_Period.week, 'This week'),
              (_Period.all, 'All time'),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SectionLabel('Net earnings', padding: EdgeInsets.only(bottom: 8)),
                Text(
                  money(net),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${money(gross)} in fares · ${money(gross - net)} service fee',
                  style: TextStyle(fontSize: 13, color: c.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatBox(label: 'Trips', value: '${trips.length}'),
              const SizedBox(width: 8),
              StatBox(label: 'Distance', value: distanceLabel(km)),
              const SizedBox(width: 8),
              StatBox(label: 'Time', value: durationLabel(minutes)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatBox(
                label: 'Average fare',
                value: trips.isEmpty
                    ? '—'
                    : money((net / trips.length).round(), decimals: false),
              ),
              const SizedBox(width: 8),
              StatBox(
                label: 'Rating',
                value: avgRating.toStringAsFixed(2),
                tone: c.accent,
              ),
              const SizedBox(width: 8),
              StatBox(
                label: 'Per hour',
                value: minutes == 0
                    ? '—'
                    : money((net / minutes * 60).round(), decimals: false),
                tone: c.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (grouped.isEmpty)
            const EmptyState(
              icon: Icons.trending_up_rounded,
              title: 'No completed trips yet',
              body: 'Go online and accept an order — your earnings will show up here.',
            )
          else
            for (final entry in grouped.entries) ...[
              SectionLabel(entry.key, padding: const EdgeInsets.only(bottom: 8)),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++)
                      Container(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(top: BorderSide(color: c.line)),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/ride/${entry.value[i].id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: c.surface2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.directions_car_rounded,
                                    size: 16,
                                    color: c.textDim,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.value[i].dropoff.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${clockTime(entry.value[i].completedAt ?? entry.value[i].createdAt)} · '
                                        '${distanceLabel(entry.value[i].distanceKm)}'
                                        '${entry.value[i].ratingByPassenger != null ? ' · ★ ${entry.value[i].ratingByPassenger!.stars}' : ''}',
                                        style: TextStyle(fontSize: 12, color: c.textDim),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  money(driverNet(entry.value[i].fare), decimals: false),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}
