import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    final asPassenger = rides
        .historyFor(user.id, Role.passenger)
        .where((r) => r.status == RideStatus.completed)
        .length;
    final asDriver = rides
        .historyFor(user.id, Role.driver)
        .where((r) => r.status == RideStatus.completed)
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => _edit(context, session, user),
            child: Text('Edit', style: TextStyle(color: c.brand)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                Avatar(name: user.name, color: user.avatarColor, size: 92),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  phoneDisplay(user.phone),
                  style: TextStyle(fontSize: 13.5, color: c.textDim),
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: TextStyle(fontSize: 13, color: c.textMute),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              StatBox(
                label: 'Passenger rating',
                value: user.rating.toStringAsFixed(1),
                tone: c.brand,
              ),
              const SizedBox(width: 8),
              StatBox(label: 'Trips taken', value: '$asPassenger'),
              const SizedBox(width: 8),
              StatBox(
                label: 'Wallet',
                value: money(user.walletBalance, decimals: false),
              ),
            ],
          ),
          if (user.driverProfile != null) ...[
            const SectionLabel(
              'Driver profile',
              padding: EdgeInsets.only(top: 24, bottom: 8),
            ),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.brand.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(Icons.directions_car_rounded, size: 20, color: c.brand),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.driverProfile!.vehicle.make} '
                              '${user.driverProfile!.vehicle.model}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${user.driverProfile!.vehicle.plate} · '
                              '${user.driverProfile!.vehicle.color}',
                              style: TextStyle(fontSize: 12.5, color: c.textDim),
                            ),
                          ],
                        ),
                      ),
                      if (user.driverProfile!.verified)
                        Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 15, color: c.ok),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.ok,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      StatBox(
                        label: 'Driver rating',
                        value: user.driverProfile!.rating.toStringAsFixed(2),
                        tone: c.brand,
                      ),
                      const SizedBox(width: 8),
                      StatBox(
                        label: 'Trips given',
                        value: '${asDriver == 0 ? user.driverProfile!.ridesGiven : asDriver}',
                      ),
                      const SizedBox(width: 8),
                      StatBox(
                        label: 'Earned',
                        value: money(user.driverProfile!.earnings, decimals: false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: c.textDim),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Member since ${DateFormat('MMMM y').format(user.createdAt)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Icon(Icons.star_rounded, size: 16, color: c.brand),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            'Your rating is the average of your last 50 trips. Passengers and drivers '
            'rate each other after every completed ride.',
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, SessionStore session, AppUser user) {
    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email ?? '');
    showAppSheet(
      context,
      title: 'Edit profile',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Full name', padding: EdgeInsets.only(bottom: 6)),
          TextField(controller: name, textCapitalization: TextCapitalization.words),
          const SectionLabel('Email', padding: EdgeInsets.only(top: 16, bottom: 6)),
          TextField(controller: email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (name.text.trim().length < 2) return;
                session.updateUser(user.copyWith(
                  name: name.text.trim(),
                  email: email.text.trim().isEmpty ? null : email.text.trim(),
                ));
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
