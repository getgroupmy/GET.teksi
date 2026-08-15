import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/storage.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Malaysian emergency line.
const _emergencyNumber = '999';

const _reportReasons = [
  'Unsafe driving',
  'Driver behaviour',
  'Wrong route taken',
  'Asked for extra payment',
  'Vehicle did not match',
  'Something else',
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
    final c = context.c;
    final rides = context.watch<RidesStore>();
    final ride = widget.rideId == null ? null : rides.rides[widget.rideId];

    final shareText = ride == null
        ? 'SAFETY ALERT — please check on me.'
        : 'SAFETY ALERT — I’m on a GET.teksi trip to ${ride.dropoff.name}. '
              'Driver ${ride.driverName ?? 'unknown'}, '
              '${ride.driverVehicle?.plate ?? 'no plate'}. '
              'Ref ${ride.id.substring(ride.id.length - 6).toUpperCase()}.';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Safety centre'),
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
                            'Emergency SOS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.danger,
                            ),
                          ),
                          Text(
                            'Call $_emergencyNumber and alert your contacts',
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
                'Active trip to ${ride.dropoff.name}'
                '${ride.driverVehicle != null ? ' · ${ride.driverVehicle!.plate}' : ''}. '
                'Your contacts can see these details when you share the trip.',
              ),
            ),
          const SectionLabel('During a trip'),
          AppRow(
            icon: Icons.ios_share_rounded,
            title: 'Share my trip',
            subtitle: 'Send live trip details to someone you trust',
            onTap: () {
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trip details copied to clipboard'),
                ),
              );
            },
          ),
          AppRow(
            icon: Icons.flag_outlined,
            title: 'Report a problem',
            subtitle: 'Driving, behaviour, route or payment',
            onTap: () => _report(context, rides, ride?.id),
          ),
          AppRow(
            icon: Icons.support_agent_rounded,
            title: '24/7 support',
            subtitle: 'Talk to a GET.teksi agent',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connecting you to support…')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'EMERGENCY CONTACTS',
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
                  label: Text('Add', style: TextStyle(color: c.accent)),
                ),
              ],
            ),
          ),
          if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No contacts yet. Add someone who should be alerted if you press SOS.',
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
                  child: Text('Remove', style: TextStyle(color: c.danger)),
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
    showAppSheet(
      context,
      title: 'Emergency SOS',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We’ll place a call to $_emergencyNumber and copy your trip details so you '
            'can send them to your ${_contacts.isEmpty ? 'contacts' : '${_contacts.length} emergency contact(s)'}.',
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
                  title: 'SOS triggered',
                  body: 'Trip details copied. Support has been notified.',
                  rideId: rideId,
                );
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling $_emergencyNumber…')),
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
              label: const Text('Call $_emergencyNumber'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  void _report(BuildContext context, RidesStore rides, String? rideId) {
    showAppSheet(
      context,
      title: 'Report a problem',
      builder: (sheetContext) =>
          reasonList(sheetContext, _reportReasons, (reason) {
            rides.notify(
              kind: NotificationKind.safety,
              title: 'Report submitted',
              body: '$reason — our safety team will follow up within 24 hours.',
              rideId: rideId,
            );
            Navigator.of(sheetContext).pop();
          }),
    );
  }

  void _addContact(BuildContext context) {
    final name = TextEditingController();
    final phone = TextEditingController();
    showAppSheet(
      context,
      title: 'Add emergency contact',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Name', padding: EdgeInsets.only(bottom: 6)),
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Mum'),
          ),
          const SectionLabel(
            'Phone number',
            padding: EdgeInsets.only(top: 16, bottom: 6),
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
              child: const Text('Save contact'),
            ),
          ),
        ],
      ),
    );
  }
}
