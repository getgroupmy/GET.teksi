import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final user = session.requireUser;
    final isDriver = session.prefs.role == Role.driver;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          InkWell(
            onTap: () => context.push('/profile'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Avatar(name: user.name, color: user.avatarColor, size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            RatingChip(
                              value: isDriver
                                  ? (user.driverProfile?.rating ?? 5)
                                  : user.rating,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isDriver
                                    ? '${user.driverProfile?.ridesGiven ?? 0} trips given'
                                    : '${user.ridesTaken} trips taken',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: c.textDim),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.textMute),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  if (isDriver) {
                    session.setRole(Role.passenger);
                    context.go('/p');
                  } else if (user.isDriver) {
                    session.setRole(Role.driver);
                    context.go('/d');
                  } else {
                    context.push('/d/onboarding');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: c.surface3,
                  foregroundColor: c.text,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDriver
                          ? Icons.person_outline_rounded
                          : Icons.directions_car_filled_rounded,
                      size: 18,
                      color: c.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDriver
                          ? 'Switch to passenger'
                          : (user.isDriver ? 'Switch to driver' : 'Become a driver'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.line),
          AppRow(
            icon: Icons.history_rounded,
            title: 'My rides',
            subtitle: 'Trip history and receipts',
            onTap: () => context.push('/history'),
          ),
          AppRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Balance ${money(user.walletBalance)}',
            onTap: () => context.push('/wallet'),
          ),
          AppRow(
            icon: Icons.card_giftcard_rounded,
            title: 'Promo codes',
            subtitle: 'Discounts and referrals',
            onTap: () => context.push('/promos'),
          ),
          AppRow(
            icon: Icons.place_outlined,
            title: 'Saved places',
            subtitle: 'Home, work and favourites',
            onTap: () => context.push('/places'),
          ),
          if (user.isDriver) ...[
            Divider(height: 17, color: c.line, indent: 16, endIndent: 16),
            AppRow(
              icon: Icons.trending_up_rounded,
              title: 'Earnings',
              subtitle: 'Daily and weekly totals',
              onTap: () => context.push('/d/earnings'),
            ),
            AppRow(
              icon: Icons.directions_car_rounded,
              title: 'Vehicle & documents',
              subtitle: user.driverProfile!.vehicle.plate,
              onTap: () => context.push('/d/vehicle'),
            ),
          ],
          Divider(height: 17, color: c.line, indent: 16, endIndent: 16),
          AppRow(
            icon: Icons.shield_outlined,
            title: 'Safety centre',
            subtitle: 'Emergency contacts and SOS',
            onTap: () => context.push('/safety'),
          ),
          AppRow(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => context.push('/settings'),
          ),
          AppRow(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            danger: true,
            onTap: () => _confirmSignOut(context, session),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'GET.teksi · v1.0.0',
              style: TextStyle(fontSize: 11.5, color: c.textMute),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, SessionStore session) {
    final rides = context.read<RidesStore>();
    showAppSheet(
      context,
      title: 'Sign out?',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your rides and history stay on this device unless you clear them.',
            style: TextStyle(fontSize: 13.5, color: sheetContext.c.textDim),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: sheetContext.c.danger.withValues(alpha: 0.16),
                foregroundColor: sheetContext.c.danger,
              ),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                session.signOut();
              },
              child: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                rides.reset();
                session.signOut();
              },
              child: Text(
                'Sign out and erase all local data',
                style: TextStyle(color: sheetContext.c.textMute),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
