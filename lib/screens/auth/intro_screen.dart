import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../../theme.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    Icons.payments_outlined,
    'Name your own fare',
    'No fixed meter, no surge. You say what the trip is worth, drivers reply with their price.',
  ),
  _Slide(
    Icons.people_alt_outlined,
    'Ride and drive in one app',
    'Switch between passenger and driver whenever you like. One profile, one wallet, one history.',
  ),
  _Slide(
    Icons.verified_user_outlined,
    'Safety built in',
    'Share your trip, call for help, and see every driver’s rating before you accept a price.',
  ),
];

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _index = 0;

  void _finish() {
    final session = context.read<SessionStore>();
    session.setPrefs(session.prefs.copyWith(hasSeenIntro: true));
    context.go('/auth/phone');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final slide = _slides[_index];
    final last = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.navigation_rounded, color: c.accent, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'GET.teksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip', style: TextStyle(color: c.textDim)),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      key: ValueKey(_index),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: c.brand.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(slide.icon, size: 42, color: c.accent),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.textDim,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? c.accent : c.surface3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => last ? _finish() : setState(() => _index++),
                child: Text(last ? 'Get started' : 'Next'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
