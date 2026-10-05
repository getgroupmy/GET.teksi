import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../l10n/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../ui.dart';

/// The driver's job card. One primary button always drives the trip forward:
/// on my way → arrived → start → finish.
class ActiveRideSheet extends StatelessWidget {
  const ActiveRideSheet({
    super.key,
    required this.ride,
    required this.driverAt,
  });

  final Ride ride;
  final LatLng driverAt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final rides = context.watch<RidesStore>();
    final unread = rides.unreadChat(ride.id, Role.driver);

    final heading = ride.status == RideStatus.inProgress
        ? ride.dropoff
        : ride.pickup;
    final km = haversineKm(driverAt, heading.coord) * 1.35;
    final eta = driveMinutes(km);

    final (primaryLabel, primaryAction) = switch (ride.status) {
      RideStatus.accepted || RideStatus.arriving => (
        "I've arrived",
        () => rides.setRideStatus(ride.id, RideStatus.waiting),
      ),
      RideStatus.waiting => (
        l.startTheTrip,
        () => rides.setRideStatus(ride.id, RideStatus.inProgress),
      ),
      RideStatus.inProgress => (
        l.finishTripFor(money(ride.fare, decimals: false)),
        () => rides.completeRide(ride.id),
      ),
      _ => (null, null),
    };

    final title = switch (ride.status) {
      RideStatus.inProgress => l.toDestination(ride.dropoff.name),
      RideStatus.waiting => l.waitingForPassenger,
      _ => l.pickUpName(ride.passengerName),
    };

    // The passenger card's two halves, named so the layout below can put
    // them in a row or a column without either being written twice.
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap, not Row: the name already ellipsises, so at double the text
        // size what stops fitting is the rating chip — and a truncated
        // rating is a different number, not a shorter one.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              ride.passengerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            RatingChip(value: ride.passengerRating),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${l.passengerCount(ride.passengerCount)} · '
          '${ride.paymentMethod == PaymentMethod.cash
              ? l.cash
              : ride.paymentMethod == PaymentMethod.card
              ? l.card
              : l.wallet}',
          style: TextStyle(fontSize: 12.5, color: c.textDim),
        ),
      ],
    );

    final fare = Column(
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
          l.youGet(money(driverNet(ride.fare), decimals: false)),
          style: TextStyle(fontSize: 11, color: c.textDim),
        ),
      ],
    );

    final avatar = Avatar(
      name: ride.passengerName,
      color: ride.passengerAvatarColor,
      size: 44,
    );

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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${durationLabel(l, eta)} · ${distanceLabel(km)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
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
            // Stacked at large text rather than squeezed: the fare and the
            // rating are both numbers that have to read exactly, so once the
            // row is full there is nothing left to ellipsise.
            child: stackAtLargeText(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          avatar,
                          const SizedBox(width: 12),
                          Expanded(child: identity),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: fare),
                    ],
                  )
                : Row(
                    children: [
                      avatar,
                      const SizedBox(width: 12),
                      Expanded(child: identity),
                      fare,
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
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 15,
                    color: c.textDim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.comment!,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textDim,
                        height: 1.35,
                      ),
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
                label: l.chatLabel,
                badge: unread,
                onTap: () => context.push('/chat/${ride.id}'),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.phone_rounded,
                label: l.callLabel,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.callingName(ride.passengerName))),
                ),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.navigation_rounded,
                label: l.navigate,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.navigatingTo(heading.name))),
                ),
              ),
              const SizedBox(width: 8),
              ActionTile(
                icon: Icons.shield_outlined,
                label: l.safetyLabel,
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
                // The same shape as the price sheet's class row fixed in
                // #30 — spaceBetween with neither child flexible — and this
                // one overflowed at the normal text size, the bar every
                // screen in the app already clears.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        l.tripDistanceDuration(
                          distanceLabel(ride.distanceKm),
                          durationLabel(l, ride.durationMinutes),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.textDim),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l.feeIs(money(commissionOn(ride.fare))),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 12.5, color: c.textDim),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ride.status == RideStatus.waiting) ...[
            const SizedBox(height: 12),
            InfoBanner(l.freeWaitDriverNote),
          ],

          const SizedBox(height: 14),
          if (primaryLabel != null)
            FilledButton(onPressed: primaryAction, child: Text(primaryLabel)),
          if (ride.status != RideStatus.inProgress)
            TextButton(
              onPressed: () => _confirmCancel(context, rides),
              child: Text(l.cancelThisOrder, style: TextStyle(color: c.danger)),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, RidesStore rides) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.cancelOrderConfirmTitle,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(l.cancelOrderBody, tone: BannerTone.warn),
          const SizedBox(height: 12),
          reasonList(sheetContext, cancelReasonsDriver(l), (reason) {
            rides.cancelRide(ride.id, CancelledBy.driver, reason);
            Navigator.of(sheetContext).pop();
          }),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(l.keepTheOrder),
          ),
        ],
      ),
    );
  }
}
