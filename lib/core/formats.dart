import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Money is stored in minor units (sen) everywhere; format at the edges only.

const currencySymbol = 'RM';

final _thousands = NumberFormat('#,##0', 'en');
final _twoDp = NumberFormat('#,##0.00', 'en');

String money(int minor, {bool decimals = true, bool symbol = true}) {
  final major = minor / 100;
  final text = decimals
      ? _twoDp.format(major)
      : _thousands.format(major.round());
  return symbol ? '$currencySymbol$text' : text;
}

/// Rounds to the nearest 50 sen — riders think in half-ringgit steps.
int roundFare(num minor) {
  final rounded = (minor / 50).round() * 50;
  return rounded < 100 ? 100 : rounded;
}

String distanceLabel(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

String durationLabel(AppLocalizations l, int minutes) {
  if (minutes < 60) return l.durationMinutes(minutes);
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? l.durationHours(h) : l.durationHoursMinutes(h, m);
}

String timeAgo(AppLocalizations l, DateTime ts) {
  final secs = DateTime.now().difference(ts).inSeconds;
  if (secs < 10) return l.justNow;
  if (secs < 60) return l.secondsAgo(secs);
  final mins = secs ~/ 60;
  if (mins < 60) return l.minutesAgo(mins);
  final hours = mins ~/ 60;
  if (hours < 24) return l.hoursAgo(hours);
  final days = hours ~/ 24;
  if (days < 7) return l.daysAgo(days);
  return DateFormat.MMMd(l.localeName).format(ts);
}

String clockTime(DateTime ts) => DateFormat('HH:mm').format(ts);

String dateLabel(AppLocalizations l, DateTime ts) {
  final now = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(ts, now)) return l.today;
  if (sameDay(ts, now.subtract(const Duration(days: 1)))) return l.yesterday;
  // Same year: the year would be noise. Otherwise it is the whole point.
  return ts.year == now.year
      ? DateFormat.MMMMd(l.localeName).format(ts)
      : DateFormat.yMMMMd(l.localeName).format(ts);
}

/// "+60 12-345 6789" from a raw Malaysian number.
String phoneDisplay(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('60')) digits = digits.substring(2);
  if (digits.length < 9) return '+60 $digits';
  final head = digits.substring(0, 2);
  final mid = digits.substring(2, digits.length - 4);
  final tail = digits.substring(digits.length - 4);
  return '+60 $head-$mid $tail';
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

// plural() lived here: '$n ${n == 1 ? one : '${one}s'}'. An English-only rule
// — Malay marks number with the noun, not a suffix — so its two call sites are
// ICU plural messages in the ARB now and the helper is gone.

String compactCount(int n) => _thousands.format(n);
