import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
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
    final l = AppLocalizations.of(context)!;
    final draft = context.read<DraftStore>();
    final match = promoCodes(l)
        .where((p) => p.code.toLowerCase() == code.trim().toLowerCase())
        .firstOrNull;
    setState(() {
      if (match == null) {
        _feedback = (false, l.promoInvalid);
      } else {
        draft.setPromoCode(match.code);
        _feedback = (true, l.promoApplied(match.code, match.label));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
        title: Text(l.promoCodes),
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
                  decoration: InputDecoration(hintText: l.enterAPromoCode),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _entered.text.trim().isEmpty
                    ? null
                    : () => _apply(_entered.text),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(l.apply),
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
          SectionLabel(
            l.availableForYou,
            padding: const EdgeInsets.only(top: 24, bottom: 8),
          ),
          for (final promo in promoCodes(l))
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
                              l.minimumFareIs(
                                money(promo.minSpend!, decimals: false),
                              ),
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
                        child: Text(l.use),
                      ),
                  ],
                ),
              ),
            ),
          SectionLabel(
            l.inviteFriends,
            padding: const EdgeInsets.only(top: 16, bottom: 8),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.referralBody(money(500, decimals: false)),
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
                        tooltip: l.copyReferralCode,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referral));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.referralCodeCopied)),
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
                          text: l.inviteText(
                            referral,
                            money(500, decimals: false),
                          ),
                        ),
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.inviteCopied)));
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: Text(l.shareInvite),
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
