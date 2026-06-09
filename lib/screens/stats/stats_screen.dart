import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/study_provider.dart';
import '../../providers/word_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/l10n.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyProvider>().loadStats();
      context.read<WordProvider>().loadAllWords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sp = context.watch<StudyProvider>();
    final wp = context.watch<WordProvider>();
    final settings = context.watch<SettingsProvider>();
    final isEn = settings.languageMode == AppLanguageMode.english;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('学习统计', 'Study Stats'))),
      body: RefreshIndicator(
        onRefresh: () async { await context.read<StudyProvider>().loadStats(); await context.read<WordProvider>().loadAllWords(); },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _statsGrid(context, sp, wp, isEn),
            const SizedBox(height: 28),
            Text(context.t('学习日历', 'Learning Calendar'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(context.t('每日学习时长热力图', 'Daily study heatmap'), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(120), fontSize: 13)),
            const SizedBox(height: 16),
            _calendarCard(context, sp),
            const SizedBox(height: 16),
            _legend(context),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _statsGrid(BuildContext context, StudyProvider sp, WordProvider wp, bool isEn) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = (constraints.maxWidth - 12) / 2;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        _StatCard(w: w, icon: Icons.timer_outlined, title: context.t('今日学习', 'Today'), value: Helpers.formatDuration(sp.todayDurationSeconds, isEnglish: isEn), color: AppConstants.primaryColor),
        _StatCard(w: w, icon: Icons.hourglass_bottom, title: context.t('累计学习', 'Total'), value: Helpers.formatDuration(sp.totalDurationSeconds, isEnglish: isEn), color: AppConstants.secondaryColor),
        _StatCard(w: w, icon: Icons.menu_book, title: context.t('总单词数', 'Total Words'), value: '${wp.totalWordCount}', color: AppConstants.successColor),
        _StatCard(w: w, icon: Icons.favorite, title: context.t('收藏单词', 'Favorites'), value: '${wp.favoriteCount}', color: AppConstants.errorColor),
        _StatCard(w: w, icon: Icons.thumb_up_outlined, title: context.t('已掌握', 'Mastered'), value: '${sp.totalWordsMastered}', color: const Color(0xFF8B5CF6)),
        _StatCard(w: w, icon: Icons.quiz_outlined, title: context.t('正确率', 'Accuracy'), value: Helpers.formatAccuracy(sp.accuracy), color: sp.accuracy >= 0.6 ? AppConstants.successColor : AppConstants.errorColor),
      ]);
    });
  }

  Widget _calendarCard(BuildContext context, StudyProvider sp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withAlpha(30))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 22), onPressed: _currentMonth.isAfter(DateTime(2024, 1, 1)) ? () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)) : null, visualDensity: VisualDensity.compact),
          Text(DateFormat(context.t('yyyy年 M月', 'MMMM yyyy')).format(_currentMonth), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          IconButton(icon: const Icon(Icons.chevron_right, size: 22), onPressed: _currentMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month, 1)) ? () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)) : null, visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 12),
        Row(children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600))))).toList()),
        const SizedBox(height: 8),
        _buildMonthGrid(context, sp),
      ]),
    );
  }

  Widget _buildMonthGrid(BuildContext context, StudyProvider sp) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final sessionMap = <String, int>{};
    for (final s in sp.recentSessions) { sessionMap[s.date] = s.durationSeconds; }
    final today = DateTime.now();

    Widget cell(int? day) {
      if (day == null) return const SizedBox.shrink();
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final d = sessionMap[dateStr] ?? 0;
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      Color c;
      if (d == 0) { c = Colors.grey.shade200; } else if (d < 300) { c = AppConstants.primaryColor.withAlpha(60); } else if (d < 1800) { c = AppConstants.primaryColor.withAlpha(130); } else if (d < 3600) { c = AppConstants.primaryColor.withAlpha(190); } else { c = AppConstants.primaryColor; }
      return Tooltip(
        message: '$dateStr\n${d > 0 ? context.t('学习 ${d ~/ 60} 分钟', 'Studied ${d ~/ 60} min') : context.t('未学习', 'No study')}',
        child: Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6), border: isToday ? Border.all(color: AppConstants.accentColor, width: 2) : null), child: const AspectRatio(aspectRatio: 1)),
      );
    }

    final all = <int?>[];
    for (int i = 1; i < firstWeekday; i++) { all.add(null); }
    for (int d = 1; d <= daysInMonth; d++) { all.add(d); }

    final rows = <Widget>[];
    for (int i = 0; i < all.length; i += 7) {
      final week = all.sublist(i, (i + 7).clamp(0, all.length));
      while (week.length < 7) { week.add(null); }
      rows.add(Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: week.map((d) => Expanded(child: Center(child: cell(d)))).toList())));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _legend(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _LegendItem(color: Colors.grey.shade200, label: context.t('未学习', 'No study')),
      const SizedBox(width: 8), _LegendItem(color: AppConstants.primaryColor.withAlpha(60), label: '<5 min'),
      const SizedBox(width: 8), _LegendItem(color: AppConstants.primaryColor.withAlpha(130), label: '<30 min'),
      const SizedBox(width: 8), _LegendItem(color: AppConstants.primaryColor.withAlpha(190), label: '<1 h'),
      const SizedBox(width: 8), _LegendItem(color: AppConstants.primaryColor, label: '>1 h'),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final double w;
  final IconData icon;
  final String title, value;
  final Color color;
  const _StatCard({required this.w, required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      width: w,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withAlpha(25)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 21)),
        const SizedBox(height: 14),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
  ]);
}
