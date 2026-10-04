import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../core/storage.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// The driver's bid screen: accept the passenger's price, or counter with
/// your own. The floor is the asking price — a driver can never bid below it.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int? _counter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;
    final ride = rides.rides[widget.rideId];

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l.order),
        ),
        body: EmptyState(title: l.orderGoneTitle, body: l.orderGoneBody),
      );
    }

    final myOffer = rides.myPendingOfferFor(ride.id, user.id);
    final gone = ride.status != RideStatus.searching;

    final pickupKm = haversineKm(session.myLocation, ride.pickup.coord) * 1.35;
    final pickupEta = driveMinutes(pickupKm);

    final minBid = ride.askingPrice;
    final maxBid = roundFare(ride.askingPrice * 2);
    final bid = _counter ?? ride.askingPrice;
    final isCounter = bid != ride.askingPrice;

    void bump(int delta) =>
        setState(() => _counter = roundFare(bid + delta).clamp(minBid, maxBid));

    void send() {
      final profile = user.driverProfile;
      if (profile == null) return;
      rides.createOffer(
        Offer(
          id: uuid4(),
          rideId: ride.id,
          driverId: user.id,
          driverName: user.name,
          driverAvatarColor: user.avatarColor,
          driverRating: profile.rating,
          driverRidesGiven: profile.ridesGiven,
          vehicle: profile.vehicle,
          price: bid,
          etaMinutes: pickupEta,
          distanceKm: double.parse(pickupKm.toStringAsFixed(2)),
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(offerTtl),
          status: OfferStatus.pending,
          matchedAskingPrice: !isCounter,
        ),
      );
      context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l.rideRequest),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  name: ride.passengerName,
                  color: ride.passengerAvatarColor,
                  size: 46,
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
                              ride.passengerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RatingChip(value: ride.passengerRating),
                        ],
                      ),
                      Text(
                        ride.priceRaises > 0
                            ? '${l.postedAgo(timeAgo(l, ride.createdAt))} · '
                                  '${l.raisedTimes(ride.priceRaises)}'
                            : l.postedAgo(timeAgo(l, ride.createdAt)),
                        style: TextStyle(fontSize: 12.5, color: c.textDim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AppCard(
              child: Column(
                children: [
                  RouteStops(
                    pickup: ride.pickup.address.isEmpty
                        ? ride.pickup.name
                        : ride.pickup.address,
                    dropoff: ride.dropoff.name,
                    stop: ride.stop?.name,
                  ),
                  Divider(height: 24, color: c.line),
                  Row(
                    children: [
                      _Meta(
                        label: l.toPickup,
                        value:
                            '${distanceLabel(pickupKm)} · ${durationLabel(l, pickupEta)}',
                      ),
                      _Meta(
                        label: l.tripLength,
                        value:
                            '${distanceLabel(ride.distanceKm)} · ${durationLabel(l, ride.durationMinutes)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Meta(
                        label: l.carType,
                        value: ride.vehicleClass.labelIn(l),
                      ),
                      _Meta(
                        label: l.payment,
                        value: ride.paymentMethod == PaymentMethod.card
                            ? l.card
                            : ride.paymentMethod == PaymentMethod.wallet
                            ? l.wallet
                            : l.cash,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (ride.comment != null ||
                ride.options.isNotEmpty ||
                ride.passengerCount > 1) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ride.passengerCount > 1)
                      _Detail(
                        icon: Icons.people_alt_outlined,
                        text: l.passengerCount(ride.passengerCount),
                      ),
                    if (ride.options.isNotEmpty)
                      _Detail(
                        icon: Icons.auto_awesome_outlined,
                        text: ride.options.map((o) => o.labelIn(l)).join(', '),
                      ),
                    if (ride.comment != null)
                      _Detail(
                        icon: Icons.sticky_note_2_outlined,
                        text: ride.comment!,
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (gone)
              InfoBanner(l.orderClosedToOffers, tone: BannerTone.warn)
            else if (myOffer != null) ...[
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    SectionLabel(
                      l.yourOffer,
                      padding: const EdgeInsets.only(bottom: 8),
                    ),
                    Text(
                      money(myOffer.price, decimals: false),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.waitingForReply(ride.passengerName),
                      style: TextStyle(fontSize: 13, color: c.textDim),
                    ),
                    const SizedBox(height: 14),
                    const RadarBar(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    rides.withdrawOffer(myOffer.id);
                    context.pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: c.danger.withValues(alpha: 0.14),
                    foregroundColor: c.danger,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l.withdrawOffer),
                ),
              ),
            ] else ...[
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionLabel(
                          l.passengerOffers,
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          l.marketPrice(
                            money(ride.recommendedPrice, decimals: false),
                          ),
                          style: TextStyle(fontSize: 12, color: c.textDim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Round(
                          icon: Icons.remove_rounded,
                          tooltip: l.lowerOffer,
                          onTap: bid <= minBid ? null : () => bump(-50),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                money(bid, decimals: false),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.youKeepAfterFee(
                                  money(driverNet(bid)),
                                  money(commissionOn(bid)),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Round(
                          icon: Icons.add_rounded,
                          tooltip: l.raiseOffer,
                          onTap: bid >= maxBid ? null : () => bump(50),
                        ),
                      ],
                    ),
                    if (isCounter)
                      TextButton(
                        onPressed: () => setState(() => _counter = null),
                        child: Text(
                          l.resetTo(money(ride.askingPrice, decimals: false)),
                          style: TextStyle(color: c.accent),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCounter) ...[
                const SizedBox(height: 12),
                InfoBanner(l.counterOfferWarning, tone: BannerTone.warn),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: send,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  isCounter
                      ? l.offerAmount(money(bid, decimals: false))
                      : l.acceptAmount(
                          money(ride.askingPrice, decimals: false),
                        ),
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  l.skipThisOrder,
                  style: TextStyle(color: c.textDim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: context.c.textMute),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.c.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: tooltip,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Material(
          color: c.surface2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 21)),
          ),
        ),
      ),
    );
  }
}
