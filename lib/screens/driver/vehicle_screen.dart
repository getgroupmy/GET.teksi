import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
          title: Text(l.vehicle),
        ),
        body: EmptyState(
          title: l.notADriverTitle,
          body: l.notADriverBody,
          action: FilledButton(
            onPressed: () => context.push('/d/onboarding'),
            child: Text(l.becomeADriver),
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
        title: Text(l.vehicleAndDocuments),
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
                            '${vehicle.color} · ${vehicle.year} · '
                            '${l.seatCount(vehicle.seats)}',
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
                      l.category,
                      style: TextStyle(fontSize: 13, color: c.textDim),
                    ),
                    Text(
                      vehicle.vehicleClass.labelIn(l),
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
                    child: Text(l.editDetails),
                  ),
                ),
              ],
            ),
          ),
          SectionLabel(
            l.documents,
            padding: const EdgeInsets.only(top: 20, bottom: 8),
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
          InfoBanner(l.documentsNote),
        ],
      ),
    );
  }

  void _edit(BuildContext context, SessionStore session, Vehicle vehicle) {
    final l = AppLocalizations.of(context)!;
    final plate = TextEditingController(text: vehicle.plate);
    final color = TextEditingController(text: vehicle.color);
    showAppSheet(
      context,
      title: l.editVehicle,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            l.plateNumber,
            padding: const EdgeInsets.only(bottom: 6),
          ),
          TextField(
            controller: plate,
            textCapitalization: TextCapitalization.characters,
          ),
          SectionLabel(
            l.colour,
            padding: const EdgeInsets.only(top: 16, bottom: 6),
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
              child: Text(l.saveChanges),
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
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final (label, color, icon) = switch (document.status) {
      DocumentStatus.approved => (l.docApproved, c.ok, Icons.verified_rounded),
      DocumentStatus.pending => (l.docInReview, c.warn, Icons.schedule_rounded),
      DocumentStatus.rejected => (
        l.docRejected,
        c.danger,
        Icons.error_outline_rounded,
      ),
      DocumentStatus.missing => (
        l.docNotUploaded,
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
                    l.expiresDate(
                      DateFormat.yMMM(
                        Localizations.localeOf(context).languageCode,
                      ).format(document.expiresAt!),
                    ),
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
