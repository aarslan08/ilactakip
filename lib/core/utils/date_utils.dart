import 'package:intl/intl.dart';

/// Tarih işlemleri için yardımcı sınıf
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM', 'tr_TR');
  static final DateFormat _weekdayFormat = DateFormat('EEEE', 'tr_TR');

  /// Saat formatı (HH:mm)
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// HH:mm string'i parse eder
  static DateTime? parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Tarih formatı (dd MMM yyyy)
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// Tarih ve saat formatı
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Gün ve ay formatı
  static String formatDayMonth(DateTime dateTime) {
    return _dayMonthFormat.format(dateTime);
  }

  /// Haftanın günü
  static String formatWeekday(DateTime dateTime) {
    return _weekdayFormat.format(dateTime);
  }

  /// Bugün mü kontrolü
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Yarın mı kontrolü
  static bool isTomorrow(DateTime dateTime) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  /// Dün mü kontrolü
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Günün başlangıcı
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Günün sonu
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59);
  }

  /// İki tarih arasındaki gün farkı
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return to.difference(from).inDays;
  }

  /// Geçen süreyi insan dostu formatta döndürür
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return formatDate(dateTime);
    }
  }
}
