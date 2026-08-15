import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

const _topups = [1000, 2000, 5000, 10000];

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Wallet'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.brand, const Color(0xFF8FC400)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BALANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: c.brandInk.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  money(user.walletBalance),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: c.brandInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.brandInk.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _topUp(context, session, rides),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Top up'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/promos'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Promos'),
                ),
              ),
            ],
          ),
          const SectionLabel(
            'Payment methods',
            padding: EdgeInsets.only(top: 24, bottom: 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppRow(
              icon: Icons.credit_card_rounded,
              title: 'Visa ···4821',
              subtitle: 'Expires 09/28',
              trailing: Text(
                'Default',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.brand,
                ),
              ),
            ),
          ),
          const SectionLabel('Activity', padding: EdgeInsets.only(top: 24, bottom: 8)),
          if (rides.transactions.isEmpty)
            const EmptyState(
              title: 'No transactions yet',
              body: 'Rides, top-ups and payouts appear here.',
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rides.transactions.length; i++)
                    _TxnRow(txn: rides.transactions[i], first: i == 0),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const InfoBanner(
            'Cash trips are settled directly with the driver and don’t move your '
            'wallet balance.',
          ),
        ],
      ),
    );
  }

  void _topUp(BuildContext context, SessionStore session, RidesStore rides) {
    showAppSheet(
      context,
      title: 'Top up your wallet',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charged to Visa ···4821.',
            style: TextStyle(fontSize: 13.5, color: sheetContext.c.textDim),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final amount in _topups)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    session.creditWallet(amount);
                    rides.addTransaction(
                      kind: TransactionKind.topup,
                      amount: amount,
                      description: 'Top-up from card ···4821',
                    );
                    Navigator.of(sheetContext).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sheetContext.c.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      money(amount, decimals: false),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.first});

  final Txn txn;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final positive = txn.amount > 0;
    return Container(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
            child: Icon(
              positive ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 16,
              color: positive ? c.ok : c.textDim,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  timeAgo(txn.createdAt),
                  style: TextStyle(fontSize: 12, color: c.textMute),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '−'}${money(txn.amount.abs())}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: positive ? c.ok : c.text,
            ),
          ),
        ],
      ),
    );
  }
}
