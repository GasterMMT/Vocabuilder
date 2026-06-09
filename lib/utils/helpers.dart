import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static String formatDuration(int totalSeconds, {bool isEnglish = false}) {
    if (totalSeconds < 60) {
      return isEnglish ? '${totalSeconds}s' : '${totalSeconds}秒';
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return isEnglish ? '${hours}h ${minutes}m' : '${hours}小时${minutes}分钟';
    }
    return isEnglish ? '${minutes}m' : '${minutes}分钟';
  }

  static String formatDurationShort(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  static String formatAccuracy(double accuracy) {
    return '${(accuracy * 100).toStringAsFixed(1)}%';
  }

  static String todayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static DateTime todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
