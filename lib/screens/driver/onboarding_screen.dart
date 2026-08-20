import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/models.dart';
import '../../services/pricing.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Seats per category. Data rather than copy — this number is written into
/// the Vehicle record, so it stays a constant.
const _classSeats = <VehicleClass, int>{
  VehicleClass.economy: 4,
  VehicleClass.comfort: 4,
  VehicleClass.xl: 7,
};

/// The example cars shown beside each category. Copy, so it is localised and
/// cannot live in a const map.
String _classHint(AppLocalizations l, VehicleClass vehicleClass) =>
    switch (vehicleClass) {
      VehicleClass.economy => l.classHintEconomy,
      VehicleClass.comfort => l.classHintComfort,
      VehicleClass.xl => l.classHintXl,
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
    final l = AppLocalizations.of(context)!;
    final session = context.read<SessionStore>();
    session.becomeDriver(
      Vehicle(
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.parse(_year.text),
        // The same word the field showed as its placeholder, so leaving it
        // blank stores what the driver was shown rather than something else.
        color: _color.text.trim().isEmpty ? l.colourHint : _color.text.trim(),
        plate: _plate.text.trim().toUpperCase(),
        vehicleClass: _class,
        seats: _classSeats[_class]!,
      ),
    );
    session.setPrefs(
      session.prefs.copyWith(role: Role.driver, driverOnline: true),
    );
    context.go('/d');
  }

  @override
  Widget build(BuildContext context) {
    return _onVehicleStep
        ? _buildVehicleStep(context)
        : _buildIntroStep(context);
  }

  Widget _buildIntroStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                  Text(
                    l.driverIntroTitle,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.driverIntroBody,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: c.textDim,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Perk(
                    icon: Icons.account_balance_wallet_outlined,
                    title: l.perkKeepTitle(
                      '${((1 - commissionRate) * 100).round()}',
                    ),
                    body: l.perkKeepBody(
                      (commissionRate * 100).toStringAsFixed(1),
                    ),
                  ),
                  _Perk(
                    icon: Icons.schedule_rounded,
                    title: l.perkHoursTitle,
                    body: l.perkHoursBody,
                  ),
                  _Perk(
                    icon: Icons.verified_user_outlined,
                    title: l.perkChoiceTitle,
                    body: l.perkChoiceBody,
                  ),
                  const SizedBox(height: 16),
                  InfoBanner(l.driverIntroDocsNote),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: FilledButton(
              onPressed: () => setState(() => _onVehicleStep = true),
              child: Text(l.continueLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _onVehicleStep = false),
        ),
        title: Text(l.yourVehicle),
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
                          label: l.make,
                          controller: _make,
                          hint: 'Perodua',
                          autofocus: true,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: l.model,
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
                          label: l.year,
                          controller: _year,
                          hint: '2022',
                          numeric: true,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: l.colour,
                          controller: _color,
                          hint: l.colourHint,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: l.plateNumber,
                    controller: _plate,
                    hint: 'WXY 1234',
                    uppercase: true,
                    onChanged: () => setState(() {}),
                  ),
                  SectionLabel(
                    l.vehicleCategory,
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                  ),
                  for (final option in VehicleClass.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _class = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _class == option
                                  ? c.accent
                                  : Colors.transparent,
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
                                      option.labelIn(l),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_classHint(l, option)} · '
                                      '${l.seatCount(_classSeats[option]!)}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: c.textDim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_class == option)
                                Icon(
                                  Icons.check_rounded,
                                  color: c.accent,
                                  size: 20,
                                ),
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
              child: Text(l.startDriving),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textDim,
                    height: 1.35,
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
          textCapitalization: uppercase
              ? TextCapitalization.characters
              : TextCapitalization.words,
          inputFormatters: [
            if (numeric) FilteringTextInputFormatter.digitsOnly,
            if (numeric) LengthLimitingTextInputFormatter(4),
            if (uppercase)
              TextInputFormatter.withFunction(
                (_, next) => next.copyWith(text: next.text.toUpperCase()),
              ),
          ],
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
