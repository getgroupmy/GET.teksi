import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/backend.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';

/// Phone entry.
///
/// With a backend configured this asks Supabase to send a real OTP. Without
/// one there is no SMS gateway: the next screen shows the code it "sent" and
/// accepts it, so the flow stays fully walkable with nothing provisioned.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  String _digits = '';
  String _error = '';
  bool _sending = false;

  bool get _valid => _digits.length >= 9 && _digits.length <= 10;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_valid || _sending) return;
    final phone = '60$_digits';
    // Captured before the await: reaching for an inherited widget through
    // `context` after an async gap is exactly the lint this avoids.
    final l = AppLocalizations.of(context)!;

    if (!Backend.isLive) {
      context.push('/auth/otp', extra: phone);
      return;
    }

    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      await Backend.sendOtp(phone);
      if (!mounted) return;
      context.push('/auth/otp', extra: phone);
    } catch (e) {
      if (!mounted) return;
      // The number is the one thing the user can act on, so say what failed
      // rather than dropping them on a code screen no code will ever reach.
      setState(() => _error = l.phoneSendFailed);
      debugPrint('sendOtp failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/intro'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.phoneTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.phoneSubtitle,
                style: TextStyle(fontSize: 14, color: c.textDim),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      '🇲🇾 +60',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: c.textDim,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 1, height: 22, color: c.line),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (v) => setState(() => _digits = v),
                        onSubmitted: (_) => _continue(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: '12 345 6789',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _error,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l.phoneTerms,
                style: TextStyle(fontSize: 12, color: c.textMute, height: 1.45),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _valid && !_sending ? _continue : null,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(l.continueLabel),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
