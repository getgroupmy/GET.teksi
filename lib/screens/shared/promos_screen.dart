import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../data/fixtures.dart';
import '../../state/draft.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class PromosScreen extends StatefulWidget {
  const PromosScreen({super.key});

  @override
  State<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<PromosScreen> {
  final _entered = TextEditingController();
  (bool ok, String text)? _feedback;

  @override
  void dispose() {
    _entered.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final draft = context.read<DraftStore>();
    final match = promoCodes()
        .where((p) => p.code.toLowerCase() == code.trim().toLowerCase())
        .firstOrNull;
    setState(() {
      if (match == null) {
        _feedback = (false, 'That code isn’t valid or has expired.');
      } else {
        draft.setPromoCode(match.code);
        _feedback = (true, '${match.code} applied — ${match.label}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = context.watch<SessionStore>().requireUser;
    final draft = context.watch<DraftStore>();
    final referral =
        'TEKSI-${user.id.substring(user.id.length - 5).toUpperCase()}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Promo codes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entered,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() => _feedback = null),
                  onSubmitted: _apply,
                  decoration: const InputDecoration(
                    hintText: 'Enter a promo code',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _entered.text.trim().isEmpty
                    ? null
                    : () => _apply(_entered.text),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: const Text('Apply'),
              ),
            ],
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            InfoBanner(
              _feedback!.$2,
              tone: _feedback!.$1 ? BannerTone.ok : BannerTone.danger,
            ),
          ],
          const SectionLabel(
            'Available for you',
            padding: EdgeInsets.only(top: 24, bottom: 8),
          ),
          for (final promo in promoCodes())
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                border: draft.promoCode == promo.code
                    ? c.brand.withValues(alpha: 0.45)
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.brand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 20,
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.code,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            promo.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textDim,
                              height: 1.3,
                            ),
                          ),
                          if (promo.minSpend != null)
                            Text(
                              'Minimum fare ${money(promo.minSpend!, decimals: false)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.textMute,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (draft.promoCode == promo.code)
                      Icon(Icons.check_rounded, color: c.accent)
                    else
                      FilledButton.tonal(
                        onPressed: () => _apply(promo.code),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('Use'),
                      ),
                  ],
                ),
              ),
            ),
          const SectionLabel(
            'Invite friends',
            padding: EdgeInsets.only(top: 16, bottom: 8),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give a friend ${money(500, decimals: false)} off their first ride '
                  'and get ${money(500, decimals: false)} when they take it.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.textDim,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          referral,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: c.accent,
                        ),
                        tooltip: 'Copy referral code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referral));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral code copied'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              'Use my GET.teksi code $referral and get RM5 off your '
                              'first ride.',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('Share invite'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
