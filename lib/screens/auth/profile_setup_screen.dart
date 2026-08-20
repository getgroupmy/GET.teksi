import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/backend.dart';
import '../../data/fixtures.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.phone, this.authId});

  final String phone;

  /// The verified account's id, when a backend owns the identity. The local
  /// profile is created under it so its writes satisfy row-level security.
  final String? authId;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  bool _saving = false;

  bool get _valid => _name.text.trim().length >= 2;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_valid || _saving) return;
    final session = context.read<SessionStore>();
    final name = _name.text.trim();
    final email = _email.text.trim().isEmpty ? null : _email.text.trim();

    final user = session.signIn(widget.phone, name: name, id: widget.authId);
    session.updateUser(user.copyWith(name: name, email: email));

    // The auth trigger already created the profile row from the phone number;
    // this is where the name and colour the user just chose reach it. A
    // failure here is not fatal — the account exists and the app is usable —
    // so it is reported rather than blocking entry.
    if (Backend.isLive && widget.authId != null) {
      setState(() => _saving = true);
      try {
        await Backend.client
            .from('profiles')
            .update({
              'name': name,
              'email': email,
              'avatar_color': user.avatarColor,
            })
            .eq('id', widget.authId!);
      } catch (e) {
        debugPrint('profile update failed: $e');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

    if (!mounted) return;
    context.go('/p');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final display = _name.text.trim().isEmpty ? '?' : _name.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What should we call you?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Drivers and passengers will see this name and photo.',
                style: TextStyle(fontSize: 14, color: c.textDim),
              ),
              const SizedBox(height: 28),
              Center(
                child: Avatar(
                  name: display,
                  color: pickAvatarColor(
                    display == '?' ? widget.phone : display,
                  ),
                  size: 92,
                ),
              ),
              const SizedBox(height: 28),
              const SectionLabel(
                'Full name',
                padding: EdgeInsets.only(bottom: 8),
              ),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _finish(),
                decoration: const InputDecoration(
                  hintText: 'e.g. Aiman Rahman',
                ),
              ),
              const SectionLabel(
                'Email (optional)',
                padding: EdgeInsets.only(top: 20, bottom: 8),
              ),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _finish(),
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _valid ? _finish : null,
                child: const Text('Start riding'),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
