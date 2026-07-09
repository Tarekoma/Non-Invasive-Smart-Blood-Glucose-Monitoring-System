// lib/core/utils/date_formatter.dart

import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

/// Stateless date/time formatting helpers.
abstract final class DateFormatter {
  /// Returns e.g. "Mar 25, 2026" — [locale] localizes month/weekday names
  /// (pass `Localizations.localeOf(context).toString()` from a widget).
  static String formatDate(DateTime dt, [String? locale]) =>
      DateFormat('MMM d, yyyy', locale).format(dt);

  /// Returns e.g. "10:24 AM"
  static String formatTime(DateTime dt, [String? locale]) =>
      DateFormat('h:mm a', locale).format(dt);

  /// Returns a human-friendly relative label:
  /// "Today", "Yesterday", or "N days ago" (up to 6 days),
  /// then falls back to [formatDate] for older dates.
  static String formatRelative(
    DateTime dt,
    AppLocalizations l10n, [
    String? locale,
  ]) {
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    if (diff <= 6) return l10n.dateDaysAgo(diff);
    return formatDate(dt, locale);
  }
}
