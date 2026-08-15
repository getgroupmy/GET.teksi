import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

const _classHints = <VehicleClass, (String, int)>{
  VehicleClass.economy: ('Perodua, Proton, small sedans', 4),
  VehicleClass.comfort: ('Honda City, Toyota Vios and up', 4),
  VehicleClass.xl: ('MPVs and 7-seaters', 7),
};

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  bool _onVehicleStep = false;
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();
  VehicleClass _class = VehicleClass.economy;

  bool get _valid {
    final year = int.tryParse(_year.text) ?? 0;
    return _make.text.trim().length >= 2 &&
        _model.text.trim().isNotEmpty &&
        _plate.text.trim().length >= 4 &&
        year >= 2000 &&
        year <= DateTime.now().year + 1;
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _plate.dispose();
    super.dispose();
  }

  void _finish() {
    if (!_valid) return;
    final session = context.read<SessionStore>();
    session.becomeDriver(Vehicle(
      make: _make.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text),
      color: _color.text.trim().isEmpty ? 'Silver' : _color.text.trim(),
      plate: _plate.text.trim().toUpperCase(),
      vehicleClass: _class,
      seats: _classHints[_class]!.$2,
    ));
    session.setPrefs(
      session.prefs.copyWith(role: Role.driver, driverOnline: true),
    );
    context.go('/d');
  }

  @override
  Widget build(BuildContext context) {
    return _onVehicleStep ? _buildVehicleStep(context) : _buildIntroStep(context);
  }

  Widget _buildIntroStep(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/p'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start earning with your car',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'See ride requests near you, choose the ones worth your time, '
                    'and set your own price on every trip.',
                    style: TextStyle(fontSize: 14.5, color: c.textDim, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  _Perk(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Keep ${((1 - commissionRate) * 100).round()}% of every fare',
                    body: 'Our service fee is ${(commissionRate * 100).toStringAsFixed(1)}% '
                        '— no surge splits, no hidden cuts.',
                  ),
                  const _Perk(
                    icon: Icons.schedule_rounded,
                    title: 'Drive when you want',
                    body: 'Go online and offline in one tap. No shifts, no quotas.',
                  ),
                  const _Perk(
                    icon: Icons.verified_user_outlined,
                    title: 'You choose the order',
                    body: 'See the destination and the fare before you accept anything.',
                  ),
                  const SizedBox(height: 16),
                  const InfoBanner(
                    'This build verifies documents automatically so you can try the '
                    'driver side right away.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: FilledButton(
              onPressed: () => setState(() => _onVehicleStep = true),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStep(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _onVehicleStep = false),
        ),
        title: const Text('Your vehicle'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Make',
                          controller: _make,
                          hint: 'Perodua',
                          autofocus: true,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Model',
                          controller: _model,
                          hint: 'Myvi',
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Year',
                          controller: _year,
                          hint: '2022',
                          numeric: true,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Colour',
                          controller: _color,
                          hint: 'White',
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Plate number',
                    controller: _plate,
                    hint: 'WXY 1234',
                    uppercase: true,
                    onChanged: () => setState(() {}),
                  ),
                  const SectionLabel(
                    'Vehicle category',
                    padding: EdgeInsets.only(top: 24, bottom: 8),
                  ),
                  for (final option in VehicleClass.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _class = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _class == option ? c.accent : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_classHints[option]!.$1} · ${_classHints[option]!.$2} seats',
                                      style: TextStyle(fontSize: 12.5, color: c.textDim),
                                    ),
                                  ],
                                ),
                              ),
                              if (_class == option)
                                Icon(Icons.check_rounded, color: c.accent, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: FilledButton(
              onPressed: _valid ? _finish : null,
              child: const Text('Start driving'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 13, color: c.textDim, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.numeric = false,
    this.uppercase = false,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool numeric;
  final bool uppercase;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label, padding: const EdgeInsets.only(bottom: 6)),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          textCapitalization:
              uppercase ? TextCapitalization.characters : TextCapitalization.words,
          inputFormatters: [
            if (numeric) FilteringTextInputFormatter.digitsOnly,
            if (numeric) LengthLimitingTextInputFormatter(4),
            if (uppercase) TextInputFormatter.withFunction(
              (_, next) => next.copyWith(text: next.text.toUpperCase()),
            ),
          ],
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
