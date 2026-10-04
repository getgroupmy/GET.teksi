import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/models.dart';
import '../../state/draft.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

const _tips = [0, 200, 500, 1000];

class RateScreen extends StatefulWidget {
  const RateScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int _stars = 0;
  final _tags = <String>{};
  final _comment = TextEditingController();
  int _tip = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _leave(Role viewer) {
    if (viewer == Role.passenger) context.read<DraftStore>().clearRoute();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(viewer == Role.driver ? '/d' : '/p');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.read<RidesStore>();
    final user = session.requireUser;
    final ride = rides.rides[widget.rideId];

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.rate)),
        body: EmptyState(title: l.rideNotFound),
      );
    }

    final viewer = ride.driverId == user.id ? Role.driver : Role.passenger;
    final other = viewer == Role.driver
        ? (ride.passengerName, ride.passengerAvatarColor)
        : (
            ride.driverName ?? l.driverLabel,
            ride.driverAvatarColor ?? 0xFF9AA39D,
          );

    final tagPool = _stars == 0
        ? const <String>[]
        : viewer == Role.driver
        ? (_stars >= 4 ? driverRatingTagsGood(l) : driverRatingTagsBad(l))
        : (_stars >= 4 ? ratingTagsGood(l) : ratingTagsBad(l));

    void submit() {
      rides.rateRide(
        widget.rideId,
        viewer,
        RideRating(
          stars: _stars == 0 ? 5 : _stars,
          tags: _tags.toList(),
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          createdAt: DateTime.now(),
        ),
        tip: viewer == Role.passenger && _tip > 0 ? _tip : null,
      );
      _leave(viewer);
    }

    void skip() {
      // Skipping still records a neutral rating so the ride leaves the queue.
      rides.rateRide(
        widget.rideId,
        viewer,
        RideRating(stars: 5, tags: const [], createdAt: DateTime.now()),
      );
      _leave(viewer);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l.tripCompleted),
        actions: [
          TextButton(
            onPressed: skip,
            child: Text(l.skip, style: TextStyle(color: c.textDim)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  AppCard(
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
                              '${distanceLabel(ride.distanceKm)} · ${durationLabel(l, ride.durationMinutes)}',
                              style: TextStyle(fontSize: 13, color: c.textDim),
                            ),
                            Text(
                              money(ride.fare, decimals: false),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Avatar(name: other.$1, color: other.$2, size: 76),
                  const SizedBox(height: 12),
                  Text(
                    other.$1,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    viewer == Role.driver
                        ? l.howWasYourTripDriver
                        : l.howWasYourTrip,
                    style: TextStyle(fontSize: 13.5, color: c.textDim),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var n = 1; n <= 5; n++)
                        Semantics(
                          button: true,
                          label: '$n ${n == 1 ? 'star' : 'stars'}',
                          child: IconButton(
                            onPressed: () => setState(() {
                              _stars = n;
                              _tags.clear();
                            }),
                            icon: Icon(
                              n <= _stars
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 38,
                              color: n <= _stars ? c.accent : c.surface3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (tagPool.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final tag in tagPool)
                          AppChip(
                            label: tag,
                            selected: _tags.contains(tag),
                            onTap: () => setState(() {
                              _tags.contains(tag)
                                  ? _tags.remove(tag)
                                  : _tags.add(tag);
                            }),
                          ),
                      ],
                    ),
                  ],
                  if (_stars > 0) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _comment,
                      maxLines: 2,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: l.addACommentOptional,
                      ),
                    ),
                  ],
                  if (viewer == Role.passenger && _stars >= 4) ...[
                    const SizedBox(height: 8),
                    SectionLabel(
                      l.addATipFor(other.$1.split(' ').first),
                      padding: const EdgeInsets.only(bottom: 8),
                    ),
                    Row(
                      children: [
                        for (final value in _tips)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: value == _tips.last ? 0 : 8,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () => setState(() => _tip = value),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _tip == value
                                        ? c.brand.withValues(alpha: 0.16)
                                        : c.surface2,
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: _tip == value
                                          ? c.brand.withValues(alpha: 0.4)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    value == 0
                                        ? l.none
                                        : money(value, decimals: false),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _tip == value ? c.accent : c.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: FilledButton(
                onPressed: _stars == 0 ? null : submit,
                child: Text(
                  _tip > 0
                      ? l.submitAndTip(money(_tip, decimals: false))
                      : l.submitRating,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
