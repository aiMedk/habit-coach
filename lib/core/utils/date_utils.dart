/// T008: Date/timezone helper utilities.
/// Pure Dart — no Flutter imports. Used throughout domain and data layers.
abstract final class HabitDateUtils {
  /// Converts a UTC [dateTime] to a local calendar date string (yyyy-MM-dd)
  /// in the given IANA [timezone].
  ///
  /// Note: Full IANA timezone conversion requires the `timezone` package or
  /// server-side derivation. This implementation uses the device's local offset
  /// as a fallback. For production, pass the user's stored timezone to the
  /// Supabase layer which derives [localDate] server-side at write time.
  static DateTime toLocalDate(DateTime dateTime) {
    return DateTime(
      dateTime.toLocal().year,
      dateTime.toLocal().month,
      dateTime.toLocal().day,
    );
  }

  /// Returns today's local calendar date (no time component).
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns yesterday's local calendar date.
  static DateTime yesterday() => today().subtract(const Duration(days: 1));

  /// Returns true if [dateTime] falls within the morning check-in window
  /// (5:00 AM – 11:59 AM local time).
  static bool isMorningWindow(DateTime dateTime) {
    final local = dateTime.toLocal();
    return local.hour >= 5 && local.hour < 12;
  }

  /// Returns true if [dateTime] falls within the evening reflection window
  /// (6:00 PM – 11:59 PM local time).
  static bool isEveningWindow(DateTime dateTime) {
    final local = dateTime.toLocal();
    return local.hour >= 18;
  }

  /// Returns true if [completedAt] is within the 5-minute undo window
  /// relative to [now].
  static bool isWithinUndoWindow(DateTime completedAt, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return reference.difference(completedAt).inMinutes < 5;
  }

  /// Returns the ISO 8601 date string (yyyy-MM-dd) for a [dateTime].
  static String toDateString(DateTime dateTime) =>
      '${dateTime.year.toString().padLeft(4, '0')}'
      '-${dateTime.month.toString().padLeft(2, '0')}'
      '-${dateTime.day.toString().padLeft(2, '0')}';

  /// Parses an ISO 8601 date-only string (yyyy-MM-dd) to [DateTime].
  static DateTime fromDateString(String date) => DateTime.parse(date);

  /// Returns a [DateTime] for [days] days before [from] (or today if null),
  /// with no time component.
  static DateTime daysAgo(int days, {DateTime? from}) {
    final base = from ?? today();
    return base.subtract(Duration(days: days));
  }
}
