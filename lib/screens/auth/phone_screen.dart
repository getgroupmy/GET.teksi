import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';

/// Phone entry. There is no SMS gateway here — the OTP screen shows the code
/// it "sent" and accepts it, so the flow stays fully walkable.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  String _digits = '';

  bool get _valid => _digits.length >= 9 && _digits.length <= 10;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_valid) return;
    context.push('/auth/otp', extra: '60$_digits');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
              const Text(
                'Enter your phone number',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We’ll send a 6-digit code to verify it’s you.',
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
              const SizedBox(height: 16),
              Text(
                'By continuing you agree to the Terms of Service and Privacy Policy. '
                'Standard message rates may apply.',
                style: TextStyle(fontSize: 12, color: c.textMute, height: 1.45),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _valid ? _continue : null,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
