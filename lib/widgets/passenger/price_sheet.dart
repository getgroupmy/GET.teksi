import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../core/storage.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/draft.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../ui.dart';

const _optionIcons = <RideOption, IconData>{
  RideOption.childSeat: Icons.child_friendly_outlined,
  RideOption.pet: Icons.pets_rounded,
  RideOption.luggage: Icons.luggage_outlined,
  RideOption.airCon: Icons.ac_unit_rounded,
  RideOption.noSmoking: Icons.smoke_free_rounded,
  RideOption.silentRide: Icons.volume_off_rounded,
  RideOption.femaleDriver: Icons.person_outline_rounded,
};

const _paymentIcons = <PaymentMethod, IconData>{
  PaymentMethod.cash: Icons.payments_outlined,
  PaymentMethod.card: Icons.credit_card_rounded,
  PaymentMethod.wallet: Icons.account_balance_wallet_outlined,
};

/// The signature screen: the passenger names the fare.
class PriceSheet extends StatelessWidget {
  const PriceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = AppLocalizations.of(context)!;
    final draft = context.watch<DraftStore>();
    final session = context.watch<SessionStore>();
    final rides = context.read<RidesStore>();

    final trip = draft.trip;
    final pickup = draft.pickup;
    final dropoff = draft.dropoff;
    final user = session.user;
    if (trip == null || pickup == null || dropoff == null || user == null) {
      return const SizedBox.shrink();
    }

    final price = draft.price == 0 ? trip.recommended : draft.price;
    final bounds = priceBounds(trip.recommended);
    final verdict = judgePrice(price, trip.recommended);
    final toneColor = switch (verdict.tone) {
      PriceTone.low => c.danger,
      PriceTone.high => c.info,
      PriceTone.good => c.accent,
      PriceTone.fair => c.textDim,
    };

    void bump(int delta) =>
        draft.setPrice(roundFare(price + delta).clamp(bounds.min, bounds.max));

    void publish() {
      rides.publishRide(
        Ride(
          id: uuid4(),
          passengerId: user.id,
          passengerName: user.name,
          passengerAvatarColor: user.avatarColor,
          passengerRating: user.rating,
          service: draft.service,
          vehicleClass: draft.vehicleClass,
          pickup: pickup,
          dropoff: dropoff,
          stop: draft.stop,
          askingPrice: price,
          recommendedPrice: trip.recommended,
          distanceKm: trip.distanceKm,
          durationMinutes: trip.durationMinutes,
          paymentMethod: draft.paymentMethod,
          passengerCount: draft.passengerCount,
          comment: draft.comment.trim().isEmpty ? null : draft.comment.trim(),
          options: draft.options,
          status: RideStatus.searching,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          priceRaises: 0,
          routeGeometry: syntheticRoute(pickup.coord, dropoff.coord, 3),
        ),
      );
      draft.setStep(DraftStep.idle);
    }

    return MapSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              draft.setEditing(DraftField.dropoff);
              context.push('/p/search');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: RouteStops(
                pickup: pickup.name,
                dropoff: dropoff.name,
                stop: draft.stop?.name,
                compact: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${distanceLabel(trip.distanceKm)} · ${durationLabel(trip.durationMinutes)}',
                style: TextStyle(fontSize: 13, color: c.textDim),
              ),
              InkWell(
                onTap: () => _chooseClass(context, draft),
                child: Row(
                  children: [
                    Text(
                      draft.vehicleClass.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: c.textDim,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // The fare setter — the core of the product.
          Row(
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                tooltip: 'Lower fare',
                onTap: price <= bounds.min ? null : () => bump(-bounds.step),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      money(price, decimals: false),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      verdict.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: toneColor,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundButton(
                icon: Icons.add_rounded,
                tooltip: 'Raise fare',
                onTap: price >= bounds.max ? null : () => bump(bounds.step),
              ),
            ],
          ),
          Slider(
            value: price.clamp(bounds.min, bounds.max).toDouble(),
            min: bounds.min.toDouble(),
            max: bounds.max.toDouble(),
            divisions: ((bounds.max - bounds.min) ~/ bounds.step).clamp(
              1,
              1000,
            ),
            onChanged: (v) => draft.setPrice(roundFare(v)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                money(bounds.min, decimals: false),
                style: TextStyle(fontSize: 12, color: c.textMute),
              ),
              InkWell(
                onTap: () => draft.setPrice(trip.recommended),
                child: Text(
                  l.recommendedFare(money(trip.recommended, decimals: false)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textDim,
                  ),
                ),
              ),
              Text(
                money(bounds.max, decimals: false),
                style: TextStyle(fontSize: 12, color: c.textMute),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verdict.hint,
            style: TextStyle(fontSize: 12.5, color: c.textDim, height: 1.35),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _MetaButton(
                icon: _paymentIcons[draft.paymentMethod]!,
                label: draft.paymentMethod.label,
                onTap: () =>
                    _choosePayment(context, draft, user.walletBalance, price),
              ),
              const SizedBox(width: 8),
              _MetaButton(
                icon: Icons.people_alt_outlined,
                label: '${draft.passengerCount}',
                onTap: () {
                  final max = draft.vehicleClass == VehicleClass.xl ? 6 : 4;
                  draft.setPassengerCount(
                    draft.passengerCount >= max ? 1 : draft.passengerCount + 1,
                  );
                },
              ),
              const SizedBox(width: 8),
              _MetaButton(
                icon: Icons.sticky_note_2_outlined,
                label: draft.comment.isEmpty ? l.note : l.noteAdded,
                onTap: () => _editComment(context, draft),
              ),
              const SizedBox(width: 8),
              _MetaButton(
                icon: Icons.auto_awesome_outlined,
                label: draft.options.isEmpty
                    ? l.extras
                    : '+${draft.options.length}',
                onTap: () => _chooseOptions(context, draft),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: publish,
            child: Text(l.findDriverFor(money(price, decimals: false))),
          ),
          TextButton(
            onPressed: draft.clear,
            child: Text(l.cancel, style: TextStyle(color: c.textDim)),
          ),
        ],
      ),
    );
  }

  void _chooseClass(BuildContext context, DraftStore draft) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.chooseCarType,
      builder: (sheetContext) {
        final hints = {
          VehicleClass.economy: l.carEconomy,
          VehicleClass.comfort: l.carComfort,
          VehicleClass.xl: l.carXl,
        };
        return Column(
          children: [
            for (final option in VehicleClass.values)
              AppRow(
                title: option.label,
                subtitle: hints[option],
                trailing: _Radio(selected: draft.vehicleClass == option),
                onTap: () {
                  draft.setVehicleClass(option);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        );
      },
    );
  }

  void _choosePayment(
    BuildContext context,
    DraftStore draft,
    int balance,
    int price,
  ) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.paymentMethod,
      builder: (sheetContext) {
        return Column(
          children: [
            for (final method in PaymentMethod.values)
              Builder(
                builder: (_) {
                  final insufficient =
                      method == PaymentMethod.wallet && balance < price;
                  return Opacity(
                    opacity: insufficient ? 0.45 : 1,
                    child: AppRow(
                      icon: _paymentIcons[method],
                      title: method.label,
                      subtitle: method == PaymentMethod.wallet
                          ? (insufficient
                                ? l.balanceInsufficient(money(balance))
                                : l.balanceIs(money(balance)))
                          : null,
                      trailing: _Radio(selected: draft.paymentMethod == method),
                      onTap: insufficient
                          ? null
                          : () {
                              draft.setPaymentMethod(method);
                              Navigator.of(sheetContext).pop();
                            },
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            InfoBanner(l.cashNote),
          ],
        );
      },
    );
  }

  void _editComment(BuildContext context, DraftStore draft) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: draft.comment);
    showAppSheet(
      context,
      title: l.noteForDriver,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            maxLength: 160,
            decoration: const InputDecoration(
              hintText: "e.g. I'm at the north entrance, near the taxi stand",
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              draft.setComment(controller.text);
              Navigator.of(sheetContext).pop();
            },
            child: Text(l.saveNote),
          ),
        ],
      ),
    );
  }

  void _chooseOptions(BuildContext context, DraftStore draft) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.tripOptions,
      builder: (sheetContext) => StatefulBuilder(
        builder: (innerContext, setSheetState) => Column(
          children: [
            for (final option in RideOption.values)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: draft.options.contains(option),
                onChanged: (_) {
                  draft.toggleOption(option);
                  setSheetState(() {});
                },
                secondary: Icon(
                  _optionIcons[option],
                  color: draft.options.contains(option)
                      ? innerContext.c.accent
                      : innerContext.c.textDim,
                ),
                title: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l.done),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.accent : Colors.transparent,
        border: Border.all(color: selected ? c.accent : c.line, width: 2),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
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
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 22, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaButton extends StatelessWidget {
  const _MetaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: c.textDim),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
