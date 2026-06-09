import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../utils/constants.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<StudySession> sessions;
  final int monthsToShow;

  const CalendarHeatmap({
    super.key,
    required this.sessions,
    this.monthsToShow = 6,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - monthsToShow + 1, 1);
    final endDate = now;

    final sessionMap = <String, int>{};
    for (final session in sessions) {
      sessionMap[session.date] = session.durationSeconds;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildMonths(startDate, endDate, sessionMap, context),
    );
  }

  List<Widget> _buildMonths(
      DateTime start, DateTime end, Map<String, int> sessionMap, BuildContext context) {
    final months = <Widget>[];
    var current = DateTime(start.year, start.month, 1);

    while (current.isBefore(end) || current.month == end.month) {
      months.add(_buildMonth(current, sessionMap, context));
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  Widget _buildMonth(
      DateTime month, Map<String, int> sessionMap, BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;

    final monthNames = [
      '', '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            '${month.year}年 ${monthNames[month.month]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (int i = 1; i < firstWeekday; i++)
              const SizedBox(width: 32, height: 32),
            for (int day = 1; day <= daysInMonth; day++)
              _buildDayCell(DateTime(month.year, month.month, day), sessionMap),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date, Map<String, int> sessionMap) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final duration = sessionMap[dateStr] ?? 0;

    Color color;
    if (duration == 0) {
      color = Colors.grey[200]!;
    } else if (duration < 300) {
      color = AppConstants.primaryColor.withValues(alpha: 0.3);
    } else if (duration < 1800) {
      color = AppConstants.primaryColor.withValues(alpha: 0.6);
    } else if (duration < 3600) {
      color = AppConstants.primaryColor.withValues(alpha: 0.8);
    } else {
      color = AppConstants.primaryColor;
    }

    return Tooltip(
      message: '$dateStr\n${duration > 0 ? '学习 ${duration ~/ 60} 分钟' : '未学习'}',
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
