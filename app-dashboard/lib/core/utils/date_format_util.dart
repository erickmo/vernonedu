import 'package:intl/intl.dart';

class DateFormatUtil {
  DateFormatUtil._();

  static String toDisplay(DateTime date) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(date);

  static String toDisplayWithTime(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);

  static String toApi(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String toMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);

  static String toRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return toDisplay(date);
  }
}
