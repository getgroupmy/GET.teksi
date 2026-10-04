import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/notification_setting_row.dart';
import '../../widgets/ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = AppLocalizations.of(context)!;
    final session = context.watch<SessionStore>();
    final prefs = session.prefs;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionLabel(l.appearance),
          AppRow(
            icon: prefs.darkTheme
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: l.darkTheme,
            subtitle: prefs.darkTheme ? l.on : l.off,
            trailing: Switch(
              value: prefs.darkTheme,
              onChanged: (v) => session.setPrefs(prefs.copyWith(darkTheme: v)),
            ),
          ),
          SectionLabel(l.preferences),
          AppRow(
            icon: Icons.translate_rounded,
            title: l.language,
            subtitle: l.languageName,
            onTap: () => session.setPrefs(
              prefs.copyWith(language: prefs.language == 'en' ? 'ms' : 'en'),
            ),
          ),
          const NotificationSettingRow(),
          AppRow(
            icon: Icons.volume_up_rounded,
            title: l.sounds,
            subtitle: prefs.soundEnabled ? l.on : l.off,
            trailing: Switch(
              value: prefs.soundEnabled,
              onChanged: (v) =>
                  session.setPrefs(prefs.copyWith(soundEnabled: v)),
            ),
          ),
          SectionLabel(l.demo),
          AppRow(
            icon: Icons.smart_toy_outlined,
            title: l.simulatedMarketplace,
            subtitle: l.simulatedMarketplaceRowSubtitle,
            trailing: Switch(
              value: prefs.simulationEnabled,
              onChanged: (v) =>
                  session.setPrefs(prefs.copyWith(simulationEnabled: v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: InfoBanner(l.simulationBanner),
          ),
          SectionLabel(l.about),
          AppRow(icon: Icons.description_outlined, title: l.termsOfService),
          AppRow(icon: Icons.privacy_tip_outlined, title: l.privacyPolicy),
          AppRow(
            icon: Icons.info_outline_rounded,
            title: l.version,
            subtitle: l.appNameVersion,
          ),
          AppRow(
            icon: Icons.delete_outline_rounded,
            title: l.clearLocalData,
            subtitle: l.clearLocalDataSubtitle,
            danger: true,
            onTap: () => _confirmClear(context),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l.builtWith,
              style: TextStyle(fontSize: 11.5, color: c.textMute),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rides = context.read<RidesStore>();
    showAppSheet(
      context,
      title: l.clearLocalDataConfirmTitle,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.clearLocalDataConfirmBody,
            style: TextStyle(
              fontSize: 13.5,
              color: sheetContext.c.textDim,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: sheetContext.c.danger.withValues(alpha: 0.16),
                foregroundColor: sheetContext.c.danger,
              ),
              onPressed: () {
                rides.reset();
                Navigator.of(sheetContext).pop();
              },
              child: Text(l.clearEverything),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l.cancel),
            ),
          ),
        ],
      ),
    );
  }
}
