import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/formats.dart';
import '../../theme.dart';

const _length = 6;

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _code = '';
  String _error = '';
  int _seconds = 30;
  Timer? _timer;

  /// The demo "SMS" — shown on screen instead of being sent.
  late final String _expected = () {
    var n = 7;
    for (final unit in widget.phone.codeUnits) {
      n = (n * 31 + unit) % 1000000;
    }
    return n.toString().padLeft(6, '0');
  }();

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) _seconds--;
      });
      if (_seconds == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.length != _length) return;
    if (value != _expected) {
      setState(() {
        _error = 'That code doesn’t match. Check the code shown below.';
        _code = '';
        _controller.clear();
      });
      return;
    }
    context.push('/auth/profile', extra: widget.phone);
  }

  void _autofill() {
    _controller.text = _expected;
    setState(() => _code = _expected);
    _submit(_expected);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent to ${phoneDisplay(widget.phone)}',
                style: TextStyle(fontSize: 14, color: c.textDim),
              ),
              const SizedBox(height: 32),
              Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _length; i++)
                        Expanded(
                          child: Container(
                            height: 58,
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(
                              right: i == _length - 1 ? 0 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: i == _code.length
                                    ? c.accent
                                    : (_error.isNotEmpty ? c.danger : c.line),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              i < _code.length ? _code[i] : '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_length),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _code = value;
                            _error = '';
                          });
                          if (value.length == _length) _submit(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error,
                    style: TextStyle(fontSize: 13, color: c.danger),
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: c.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.info.withValues(alpha: 0.25)),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Demo build — no SMS is sent. Your code is ',
                      style: TextStyle(fontSize: 13, color: c.info),
                    ),
                    GestureDetector(
                      onTap: _autofill,
                      child: Text(
                        _expected,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c.info,
                          decoration: TextDecoration.underline,
                          decorationColor: c.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _seconds > 0
                    ? null
                    : () => setState(() {
                        _seconds = 30;
                        _tick();
                      }),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _seconds > 0 ? 'Resend code in ${_seconds}s' : 'Resend code',
                  style: TextStyle(color: _seconds > 0 ? c.textMute : c.accent),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _code.length == _length
                    ? () => _submit(_code)
                    : null,
                child: const Text('Verify'),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
