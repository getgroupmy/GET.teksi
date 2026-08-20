import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../data/fixtures.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../ui.dart';

/// Where drivers' bids arrive while the order is on the market.
class OffersSheet extends StatefulWidget {
  const OffersSheet({super.key, required this.ride});

  final Ride ride;

  @override
  State<OffersSheet> createState() => _OffersSheetState();
}

class _OffersSheetState extends State<OffersSheet> {
  Timer? _ticker;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.ride.createdAt).inSeconds;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final rides = context.watch<RidesStore>();
    final ride = rides.rides[widget.ride.id] ?? widget.ride;
    final pending = rides.pendingOffersForRide(ride.id);

    final mins = _elapsed ~/ 60;
    final secs = _elapsed % 60;

    return MapSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.isEmpty
                          ? l.lookingForDrivers
                          : l.offersReceived(pending.length),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.yourPriceSearching(
                        money(ride.askingPrice, decimals: false),
                        '${mins > 0 ? '${mins}m ' : ''}${secs}s',
                      ),
                      style: TextStyle(fontSize: 13, color: c.textDim),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l.cancelSearch,
                color: c.textDim,
                onPressed: () => _confirmCancel(context, rides, ride),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const RadarBar(),
          const SizedBox(height: 12),

          if (pending.isEmpty) ...[
            RouteStops(
              pickup: ride.pickup.name,
              dropoff: ride.dropoff.name,
              stop: ride.stop?.name,
              compact: true,
            ),
            if (_elapsed > 20) ...[
              const SizedBox(height: 12),
              InfoBanner(l.noOffersRaisePrompt, tone: BannerTone.warn),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++) const _OfferSkeleton(),
          ] else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: pending.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _OfferCard(
                  offer: pending[i],
                  askingPrice: ride.askingPrice,
                  onAccept: () => rides.acceptOffer(pending[i].id),
                  onDecline: () => rides.declineOffer(pending[i].id),
                ),
              ),
            ),

          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _showRaise(context, rides, ride),
            style: FilledButton.styleFrom(
              backgroundColor: c.surface3,
              foregroundColor: c.text,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  l.raiseYourPrice,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRaise(BuildContext context, RidesStore rides, Ride ride) {
    final l = AppLocalizations.of(context)!;
    final suggestions = raiseSuggestions(ride.askingPrice);
    showAppSheet(
      context,
      title: l.raiseYourPrice,
      builder: (sheetContext) {
        final c = sheetContext.c;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.raiseSheetBody(money(ride.askingPrice, decimals: false)),
              style: TextStyle(fontSize: 13.5, color: c.textDim, height: 1.4),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < suggestions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    rides.raisePrice(ride.id, suggestions[i]);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: i == 1
                          ? c.brand.withValues(alpha: 0.14)
                          : c.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: i == 1
                            ? c.brand.withValues(alpha: 0.35)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          money(suggestions[i], decimals: false),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '+${money(suggestions[i] - ride.askingPrice, decimals: false)}'
                          '${i == 1 ? l.recommendedSuffix : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, RidesStore rides, Ride ride) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.cancelYourOrder,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cancelReasonPrompt,
            style: TextStyle(fontSize: 13.5, color: sheetContext.c.textDim),
          ),
          const SizedBox(height: 8),
          reasonList(sheetContext, cancelReasonsPassenger, (reason) {
            rides.cancelRide(ride.id, CancelledBy.passenger, reason);
            Navigator.of(sheetContext).pop();
          }),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(l.keepSearching),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.offer,
    required this.askingPrice,
    required this.onAccept,
    required this.onDecline,
  });

  final Offer offer;
  final int askingPrice;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  Timer? _ticker;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _update();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _update(),
    );
  }

  void _update() {
    if (!mounted) return;
    final ms = widget.offer.expiresAt.difference(DateTime.now()).inMilliseconds;
    setState(() => _secondsLeft = ms <= 0 ? 0 : (ms / 1000).ceil());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final offer = widget.offer;
    final diff = offer.price - widget.askingPrice;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: offer.matchedAskingPrice
              ? c.brand.withValues(alpha: 0.45)
              : c.line,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Avatar(
                name: offer.driverName,
                color: offer.driverAvatarColor,
                size: 42,
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
                            offer.driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RatingChip(value: offer.driverRating),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 13,
                          color: c.textDim,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${offer.vehicle.describe} · ${offer.vehicle.plate}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: c.textDim),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(offer.price, decimals: false),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diff == 0
                        ? l.yourPrice
                        : diff > 0
                        ? '+${money(diff, decimals: false)}'
                        : '−${money(-diff, decimals: false)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: diff == 0 ? c.accent : (diff > 0 ? c.warn : c.ok),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.offerMetaLine(
                    offer.etaMinutes,
                    distanceLabel(offer.distanceKm),
                    compactCount(offer.driverRidesGiven),
                  ),
                  style: TextStyle(fontSize: 12.5, color: c.textDim),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: l.declineOffer,
                onPressed: widget.onDecline,
                style: IconButton.styleFrom(
                  backgroundColor: c.surface3,
                  minimumSize: const Size(48, 48),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.onAccept,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text(l.accept),
                    const SizedBox(width: 5),
                    Text(
                      '${_secondsLeft}s',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferSkeleton extends StatelessWidget {
  const _OfferSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(140, 12), const SizedBox(height: 8), bar(90, 10)],
            ),
          ),
          bar(64, 30),
        ],
      ),
    );
  }
}
