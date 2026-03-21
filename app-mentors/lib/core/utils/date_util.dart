import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  static String toDisplay(DateTime date) =>
      DateFormat('d MMM yyyy', 'id_ID').format(date);

  static String toDisplayWithDay(DateTime date) =>
      DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);

  static String toTime(DateTime date) =>
      DateFormat('HH:mm', 'id_ID').format(date);

  static String toTimeRange(DateTime start, DateTime end) =>
      '${toTime(start)} – ${toTime(end)}';

  static String toMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static String relativeDay(DateTime date) {
    if (isToday(date)) return 'Hari Ini';
    if (isTomorrow(date)) return 'Besok';
    return toDisplayWithDay(date);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}
