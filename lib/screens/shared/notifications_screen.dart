import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the screen is the read receipt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RidesStore>().markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final notifications = context.watch<RidesStore>().notifications;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing new',
              body: 'Ride updates, offers and promos will show up here.',
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
              itemBuilder: (_, i) {
                final n = notifications[i];
                final icon = switch (n.kind) {
                  NotificationKind.ride => Icons.directions_car_rounded,
                  NotificationKind.promo => Icons.card_giftcard_rounded,
                  NotificationKind.safety => Icons.shield_outlined,
                  NotificationKind.system => Icons.info_outline_rounded,
                };
                return InkWell(
                  onTap: n.rideId == null ? null : () => context.push('/ride/${n.rideId}'),
                  child: Container(
                    color: n.read ? null : c.brand.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 17,
                            color: n.kind == NotificationKind.safety ? c.danger : c.brand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.textDim,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeAgo(n.createdAt),
                                style: TextStyle(fontSize: 11.5, color: c.textMute),
                              ),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6, left: 8),
                            decoration: BoxDecoration(
                              color: c.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
