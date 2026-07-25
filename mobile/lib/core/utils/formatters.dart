import 'package:intl/intl.dart';

/// Presentation formatters for numbers, XP, gold, dates, and durations.
abstract final class Formatters {
  const Formatters._();

  static final NumberFormat _compact = NumberFormat.compact();
  static final NumberFormat _decimal = NumberFormat.decimalPattern();

  /// `1234` → `1,234`; `1500000` → `1.5M` (compact).
  static String count(num value) => _decimal.format(value);
  static String compact(num value) => _compact.format(value);

  static String xp(num value) => '${compact(value)} XP';
  static String gold(num value) => '${compact(value)} g';

  /// `2026-07-25` period key for daily quests (matches API `periodKey`).
  static String dailyPeriodKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = that.difference(today).inDays;
    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => DateFormat('MMM d').format(date),
    };
  }

  /// Countdown like `2d 4h` / `3h 12m` / `45m`.
  static String countdown(Duration d) {
    if (d.isNegative) return 'Expired';
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  /// `95` → `95%`. Accepts a 0..1 fraction.
  static String percent(double fraction) =>
      '${(fraction.clamp(0, 1) * 100).round()}%';

  /// Title-cases an ENUM_VALUE for display: `WARRIOR` → `Warrior`,
  /// `QUESTS_COMPLETED` → `Quests Completed`.
  static String enumLabel(String raw) => raw
      .toLowerCase()
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
