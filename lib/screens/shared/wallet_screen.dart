import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/backend.dart';
import '../../core/formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

const _topups = [1000, 2000, 5000, 10000];

/// The demo card on file. One constant rather than four literals, so the
/// number the sheet charges and the number the ledger records cannot drift.
const _card = 'Visa ···4821';
const _cardTail = '···4821';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  /// The server's ledger, once it has arrived. Null means either that there is
  /// no backend — in which case the on-device ledger is the real one — or that
  /// the read has not come back yet.
  ({int balance, List<Txn> entries})? _remote;
  bool _loading = Backend.isLive;

  @override
  void initState() {
    super.initState();
    if (Backend.isLive) _load();
  }

  Future<void> _load() async {
    final wallet = await Backend.fetchWallet();
    if (!mounted) return;
    setState(() {
      _remote = wallet;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    // With a backend the money is the server's; showing the device's stale
    // copy beside it would be inventing a number. Until the read lands there
    // is nothing truthful to display, so the balance waits rather than
    // guessing.
    final remote = _remote;
    final balance = Backend.isLive ? remote?.balance : user.walletBalance;
    final entries = Backend.isLive
        ? (remote?.entries ?? const <Txn>[])
        : rides.transactions;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l.wallet),
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
                  l.balanceCaps,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: c.brandInk.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  balance == null ? '—' : money(balance),
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
                  label: Text(l.topUp),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/promos'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(l.promos),
                ),
              ),
            ],
          ),
          SectionLabel(
            l.paymentMethods,
            padding: const EdgeInsets.only(top: 24, bottom: 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppRow(
              icon: Icons.credit_card_rounded,
              title: _card,
              subtitle: l.cardExpires('09/28'),
              trailing: Text(
                l.defaultLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.brand,
                ),
              ),
            ),
          ),
          SectionLabel(
            l.activity,
            padding: const EdgeInsets.only(top: 24, bottom: 8),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (entries.isEmpty)
            EmptyState(title: l.noTransactions, body: l.noTransactionsBody)
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _TxnRow(txn: entries[i], first: i == 0),
                ],
              ),
            ),
          const SizedBox(height: 16),
          InfoBanner(l.cashTripsNote),
        ],
      ),
    );
  }

  void _topUp(BuildContext context, SessionStore session, RidesStore rides) {
    final l = AppLocalizations.of(context)!;
    // Without a backend these amounts are demo money in a demo ledger, which
    // is exactly what the on-device build is. With one, the balance is the
    // server's and it only grows when a payment provider has actually taken
    // money — there is no honest way to add to it from here, and an RPC that
    // let a client credit itself would undo the point of the ledger.
    if (Backend.isLive) {
      showAppSheet(
        context,
        title: l.topUpTitle,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.topUpUnavailable,
            style: TextStyle(
              fontSize: 13.5,
              color: sheetContext.c.textDim,
              height: 1.5,
            ),
          ),
        ),
      );
      return;
    }

    showAppSheet(
      context,
      title: l.topUpTitle,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.topUpChargedTo(_card),
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
                      description: l.topUpDescription(_cardTail),
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
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
    final l = AppLocalizations.of(context)!;
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
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
            ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeAgo(l, txn.createdAt),
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
