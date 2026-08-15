import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final profile = session.requireUser.driverProfile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Vehicle'),
        ),
        body: EmptyState(
          title: 'You’re not a driver yet',
          body: 'Set up your vehicle to start receiving orders.',
          action: FilledButton(
            onPressed: () => context.push('/d/onboarding'),
            child: const Text('Become a driver'),
          ),
        ),
      );
    }

    final vehicle = profile.vehicle;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Vehicle & documents'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.brand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 24,
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.make} ${vehicle.model}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${vehicle.color} · ${vehicle.year} · ${vehicle.seats} seats',
                            style: TextStyle(fontSize: 13, color: c.textDim),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.plate,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(fontSize: 13, color: c.textDim),
                    ),
                    Text(
                      vehicle.vehicleClass.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => _edit(context, session, vehicle),
                    child: const Text('Edit details'),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel(
            'Documents',
            padding: EdgeInsets.only(top: 20, bottom: 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < profile.documents.length; i++)
                  _DocumentRow(document: profile.documents[i], first: i == 0),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            'Documents are verified automatically in this build. In production these '
            'would be reviewed against LPKP/APAD records before a driver can go online.',
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, SessionStore session, Vehicle vehicle) {
    final plate = TextEditingController(text: vehicle.plate);
    final color = TextEditingController(text: vehicle.color);
    showAppSheet(
      context,
      title: 'Edit vehicle',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            'Plate number',
            padding: EdgeInsets.only(bottom: 6),
          ),
          TextField(
            controller: plate,
            textCapitalization: TextCapitalization.characters,
          ),
          const SectionLabel(
            'Colour',
            padding: EdgeInsets.only(top: 16, bottom: 6),
          ),
          TextField(
            controller: color,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                session.updateVehicle(
                  plate: plate.text.trim().toUpperCase(),
                  color: color.text.trim(),
                );
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.first});

  final DriverDocument document;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, color, icon) = switch (document.status) {
      DocumentStatus.approved => ('Approved', c.ok, Icons.verified_rounded),
      DocumentStatus.pending => ('In review', c.warn, Icons.schedule_rounded),
      DocumentStatus.rejected => (
        'Rejected',
        c.danger,
        Icons.error_outline_rounded,
      ),
      DocumentStatus.missing => (
        'Not uploaded',
        c.textMute,
        Icons.description_outlined,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 17, color: c.textDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (document.expiresAt != null)
                  Text(
                    'Expires ${DateFormat('MMM y').format(document.expiresAt!)}',
                    style: TextStyle(fontSize: 12, color: c.textMute),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
