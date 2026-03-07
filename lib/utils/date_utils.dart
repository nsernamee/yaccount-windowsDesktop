import 'package:intl/intl.dart';

/// 日期工具类
class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy年M月d日');
  static final DateFormat _monthFormat = DateFormat('yyyy年MM月');
  static final DateFormat _dayFormat = DateFormat('M月d日');
  static final DateFormat _chineseDateFormat = DateFormat('MM月dd日');

  /// 格式化日期为 yyyy年M月d日
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// 格式化月份为 yyyy年MM月
  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  /// 格式化日期为 M月d日
  static String formatDay(DateTime date) {
    return _dayFormat.format(date);
  }

  /// 格式化日期为 MM月dd日
  static String formatChineseDate(DateTime date) {
    return _chineseDateFormat.format(date);
  }

  /// 获取本月第一天
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取本月最后一天
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取本周第一天（周一）
  static DateTime getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断是否是今天
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 转换为月份整数 (202601)
  static int toMonthInt(DateTime date) {
    return date.year * 100 + date.month;
  }

  /// 从月份整数转换为DateTime
  static DateTime fromMonthInt(int month) {
    return DateTime(month ~/ 100, month % 100);
  }

  /// 获取相对时间描述
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return '今天';
    if (difference == 1) return '昨天';
    if (difference < 7) return '$difference天前';
    return formatDate(date);
  }
}
