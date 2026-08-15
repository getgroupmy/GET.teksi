import 'package:intl/intl.dart';

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

String durationLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String timeAgo(DateTime ts) {
  final secs = DateTime.now().difference(ts).inSeconds;
  if (secs < 10) return 'just now';
  if (secs < 60) return '${secs}s ago';
  final mins = secs ~/ 60;
  if (mins < 60) return '$mins min ago';
  final hours = mins ~/ 60;
  if (hours < 24) return '$hours h ago';
  final days = hours ~/ 24;
  if (days < 7) return '$days d ago';
  return DateFormat('d MMM').format(ts);
}

String clockTime(DateTime ts) => DateFormat('HH:mm').format(ts);

String dateLabel(DateTime ts) {
  final now = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(ts, now)) return 'Today';
  if (sameDay(ts, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return ts.year == now.year
      ? DateFormat('d MMMM').format(ts)
      : DateFormat('d MMMM y').format(ts);
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

String plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';

String compactCount(int n) => _thousands.format(n);
