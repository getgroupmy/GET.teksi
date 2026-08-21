import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/storage.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Malaysian emergency line.
const _emergencyNumber = '999';

/// A function rather than a const list: each reason is a localised string,
/// which is only known once there is a context to read it from.
List<String> _reportReasonsFor(AppLocalizations l) => [
  l.reportUnsafeDriving,
  l.reportDriverBehaviour,
  l.reportWrongRoute,
  l.reportExtraPayment,
  l.reportVehicleMismatch,
  l.reportSomethingElse,
];

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key, this.rideId});

  final String? rideId;

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<({String id, String name, String phone})> _contacts = [];

  @override
  void initState() {
    super.initState();
    _contacts = Store.instance.readJson(
      'contacts',
      const [],
      (json) => (json as List<dynamic>)
          .map(
            (e) => (
              id: (e as Map<String, dynamic>)['id'] as String,
              name: e['name'] as String,
              phone: e['phone'] as String,
            ),
          )
          .toList(),
    );
  }

  void _persist() {
    Store.instance.writeJson(
      'contacts',
      _contacts
          .map((c) => {'id': c.id, 'name': c.name, 'phone': c.phone})
          .toList(),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final rides = context.watch<RidesStore>();
    final ride = widget.rideId == null ? null : rides.rides[widget.rideId];

    final shareText = ride == null
        ? l.safetyAlertNoTrip
        : l.safetyAlertTrip(
            ride.dropoff.name,
            ride.driverName ?? l.unknownDriver,
            ride.driverVehicle?.plate ?? l.noPlate,
            ride.id.substring(ride.id.length - 6).toUpperCase(),
          );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l.safetyCentre),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _sos(context, rides, shareText, ride?.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emergency_share_rounded,
                      size: 26,
                      color: c.danger,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.emergencySos,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.danger,
                            ),
                          ),
                          Text(
                            l.emergencySosSubtitle(_emergencyNumber),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.danger.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ride != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: InfoBanner(
                l.activeTripBanner(
                  ride.dropoff.name,
                  ride.driverVehicle != null
                      ? ' · ${ride.driverVehicle!.plate}'
                      : '',
                ),
              ),
            ),
          SectionLabel(l.duringATrip),
          AppRow(
            icon: Icons.ios_share_rounded,
            title: l.shareMyTrip,
            subtitle: l.shareMyTripSubtitle,
            onTap: () {
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l.tripDetailsCopied)));
            },
          ),
          AppRow(
            icon: Icons.flag_outlined,
            title: l.reportAProblem,
            subtitle: l.reportAProblemSubtitle,
            onTap: () => _report(context, rides, ride?.id),
          ),
          AppRow(
            icon: Icons.support_agent_rounded,
            title: l.supportTitle,
            subtitle: l.supportSubtitle,
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.connectingToSupport))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.emergencyContacts,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: c.textMute,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addContact(context),
                  icon: Icon(Icons.add_rounded, size: 16, color: c.accent),
                  label: Text(l.add, style: TextStyle(color: c.accent)),
                ),
              ],
            ),
          ),
          if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l.noEmergencyContacts,
                style: TextStyle(fontSize: 13.5, color: c.textDim, height: 1.4),
              ),
            )
          else
            for (final contact in _contacts)
              AppRow(
                icon: Icons.person_outline_rounded,
                title: contact.name,
                subtitle: contact.phone,
                trailing: TextButton(
                  onPressed: () {
                    _contacts = _contacts
                        .where((x) => x.id != contact.id)
                        .toList();
                    _persist();
                  },
                  child: Text(l.remove, style: TextStyle(color: c.danger)),
                ),
              ),
        ],
      ),
    );
  }

  void _sos(
    BuildContext context,
    RidesStore rides,
    String shareText,
    String? rideId,
  ) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.emergencySos,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Two whole sentences rather than one with a fragment swapped in:
            // a language that puts the count elsewhere can then say so.
            _contacts.isEmpty
                ? l.sosBodyNoContacts(_emergencyNumber)
                : l.sosBodyWithContacts(_emergencyNumber, _contacts.length),
            style: TextStyle(
              fontSize: 13.5,
              color: sheetContext.c.textDim,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: sheetContext.c.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shareText));
                rides.notify(
                  kind: NotificationKind.safety,
                  title: l.sosTriggered,
                  body: l.sosTriggeredBody,
                  rideId: rideId,
                  // A record in the centre, not a banner: the phone is in
                  // their hand and the snackbar below already answered them.
                  alert: false,
                );
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.callingEmergency(_emergencyNumber))),
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
              label: Text(l.callEmergency(_emergencyNumber)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l.cancel),
            ),
          ),
        ],
      ),
    );
  }

  void _report(BuildContext context, RidesStore rides, String? rideId) {
    final l = AppLocalizations.of(context)!;
    showAppSheet(
      context,
      title: l.reportAProblem,
      builder: (sheetContext) =>
          reasonList(sheetContext, _reportReasonsFor(l), (reason) {
            rides.notify(
              kind: NotificationKind.safety,
              title: l.reportSubmitted,
              body: l.reportSubmittedBody(reason),
              rideId: rideId,
              alert: false,
            );
            Navigator.of(sheetContext).pop();
          }),
    );
  }

  void _addContact(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = TextEditingController();
    final phone = TextEditingController();
    showAppSheet(
      context,
      title: l.addEmergencyContact,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l.nameLabel, padding: const EdgeInsets.only(bottom: 6)),
          TextField(
            controller: name,
            autofocus: true,
            decoration: InputDecoration(hintText: l.nameHint),
          ),
          SectionLabel(
            l.phoneNumberLabel,
            padding: const EdgeInsets.only(top: 16, bottom: 6),
          ),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+60 12-345 6789'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (name.text.trim().length < 2 ||
                    phone.text.trim().length < 8) {
                  return;
                }
                _contacts = [
                  ..._contacts,
                  (
                    id: uid('ct'),
                    name: name.text.trim(),
                    phone: phone.text.trim(),
                  ),
                ];
                _persist();
                Navigator.of(sheetContext).pop();
              },
              child: Text(l.saveContact),
            ),
          ),
        ],
      ),
    );
  }
}
