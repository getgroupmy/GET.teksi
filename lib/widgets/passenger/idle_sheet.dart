import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/draft.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../ui.dart';

const _serviceIcons = <ServiceType, IconData>{
  ServiceType.city: Icons.directions_car_rounded,
  ServiceType.intercity: Icons.alt_route_rounded,
  ServiceType.delivery: Icons.inventory_2_outlined,
  ServiceType.moto: Icons.two_wheeler_rounded,
  ServiceType.freight: Icons.local_shipping_outlined,
};

class IdleSheet extends StatelessWidget {
  const IdleSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final draft = context.watch<DraftStore>();
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    final recents = <Place>[];
    final seen = <String>{};
    for (final ride in rides.historyFor(user.id, Role.passenger)) {
      if (!seen.add(ride.dropoff.name)) continue;
      recents.add(ride.dropoff.copyWith(category: PlaceCategory.recent));
      if (recents.length >= 3) break;
    }

    void quickTo(Place place) {
      draft.setDropoff(place);
      draft.setStep(DraftStep.price);
    }

    return MapSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final service in ServiceType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: service.label,
                      icon: _serviceIcons[service],
                      selected: draft.service == service,
                      onTap: () => draft.setService(service),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              draft.setEditing(DraftField.dropoff);
              context.push('/p/search');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: c.brand, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Where to?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Shortcut(
                icon: Icons.home_rounded,
                label: user.homePlace == null ? 'Add home' : 'Home',
                sub: user.homePlace?.name,
                onTap: () => user.homePlace == null
                    ? context.push('/places')
                    : quickTo(user.homePlace!),
              ),
              const SizedBox(width: 8),
              _Shortcut(
                icon: Icons.work_outline_rounded,
                label: user.workPlace == null ? 'Add work' : 'Work',
                sub: user.workPlace?.name,
                onTap: () => user.workPlace == null
                    ? context.push('/places')
                    : quickTo(user.workPlace!),
              ),
              const SizedBox(width: 8),
              _Shortcut(
                icon: Icons.add_rounded,
                label: 'Saved',
                onTap: () => context.push('/places'),
              ),
            ],
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final place in recents)
              InkWell(
                onTap: () => quickTo(place),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.history_rounded, size: 17, color: c.textDim),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              place.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: c.textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: c.brand),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (sub != null)
                Text(
                  sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.textMute),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
