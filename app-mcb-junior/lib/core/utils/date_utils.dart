import 'package:intl/intl.dart';

/// Utilitas tanggal dan waktu untuk MCB Junior.
class AppDateUtils {
  AppDateUtils._();

  static final _dayFormat = DateFormat('EEEE', 'id_ID');
  static final _shortDateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');

  /// Format: Senin, Selasa, dst
  static String dayName(DateTime date) => _dayFormat.format(date);

  /// Format: 20 Mar 2026
  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  /// Format: 14:30
  static String time(DateTime date) => _timeFormat.format(date);

  /// Apakah tanggal hari ini?
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Hitung streak dari list tanggal check-in.
  static int calculateStreak(List<DateTime> checkIns) {
    if (checkIns.isEmpty) return 0;

    final sorted = checkIns.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    for (final date in sorted) {
      if (date == current || date == current.subtract(const Duration(days: 1))) {
        streak++;
        current = date;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Greeting berdasarkan jam.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}
