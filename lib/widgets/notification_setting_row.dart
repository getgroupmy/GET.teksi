import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/notifier.dart';
import '../l10n/app_localizations.dart';
import 'ui.dart';

/// The way back in after saying no.
///
/// The permission is asked for once, after sign-in, and every platform then
/// stops offering. Android will not show the prompt again after a refusal,
/// iOS never shows it twice, and a browser remembers a denial for the origin.
/// So a single reflexive dismissal turned the whole notification feature off
/// permanently, from a dialog that appeared before the app had shown why it
/// wanted one — and the app said nothing about it anywhere.
///
/// This row is also the only place the browser can ever be asked at all: the
/// request is honoured during a user gesture and nowhere else, and a frame
/// after sign-in is not one. A tap is.
class NotificationSettingRow extends StatefulWidget {
  const NotificationSettingRow({super.key});

  @override
  State<NotificationSettingRow> createState() => _NotificationSettingRowState();
}

class _NotificationSettingRowState extends State<NotificationSettingRow>
    with WidgetsBindingObserver {
  NotificationPermission? _status;

  Notifier get _notifier => context.read<Notifier>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings screen is the whole reason this
    // observer exists: the answer changed somewhere this app cannot see, and
    // a row still reading "Off" would be wrong the moment it mattered.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await _notifier.status();
    if (mounted) setState(() => _status = status);
  }

  /// Ask, and if there is no prompt left to show, go where the answer lives.
  Future<void> _onTap() async {
    final before = _status;
    if (before != NotificationPermission.granted) {
      await _notifier.requestPermission();
      final after = await _notifier.status();
      if (!mounted) return;
      setState(() => _status = after);
      if (after == NotificationPermission.granted) return;
    }
    // Either already on and they want it off, or the prompt is spent. Both end
    // at the same screen.
    final opened = await _notifier.openSettings();
    if (!mounted || opened) return;
    // Nowhere to go — a browser. Say so rather than leaving a tap that did
    // nothing at all.
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.notificationsBlockedHint)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final status = _status;
    return AppRow(
      icon: status == NotificationPermission.granted
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined,
      title: l.notifications,
      subtitle: switch (status) {
        // The frame or two before the platform answers. Saying "off" in that
        // window would be a flicker of bad news that is not true yet.
        null => null,
        NotificationPermission.granted => l.on,
        NotificationPermission.denied => l.notificationsDeniedSubtitle,
        NotificationPermission.unavailable =>
          l.notificationsUnavailableSubtitle,
      },
      onTap: status == null || status == NotificationPermission.unavailable
          ? null
          : _onTap,
    );
  }
}
