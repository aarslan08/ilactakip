import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class CalendarHeatmap extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, double> adherenceMap;
  final void Function(DateTime) onDayTap;

  const CalendarHeatmap({
    super.key,
    required this.month,
    required this.adherenceMap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // weekday: Mon=1 … Sun=7 → leading empty slots
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final locale = Localizations.localeOf(context).languageCode;
    final dayNames = locale == 'tr'
        ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gün başlıkları
        Row(
          children: dayNames
              .map((name) => Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textLightClr,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Gün hücreleri
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) return const SizedBox.shrink();

            final dayNum = index - leadingEmpty + 1;
            final date = DateTime(month.year, month.month, dayNum);
            final dateKey = DateTime(date.year, date.month, date.day);
            final isFuture = dateKey.isAfter(todayKey);
            final isToday = dateKey == todayKey;
            final adherence = adherenceMap[dateKey];

            return GestureDetector(
              onTap: isFuture ? null : () => onDayTap(date),
              child: Container(
                decoration: BoxDecoration(
                  color: _cellColor(adherence, isFuture, context),
                  borderRadius: BorderRadius.circular(7),
                  border: isToday
                      ? Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w500,
                      color: _textColor(adherence, isFuture, isToday, context),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _cellColor(double? adherence, bool isFuture, BuildContext context) {
    if (isFuture || adherence == null) return context.subtleBg;
    if (adherence > 0.8) return AppTheme.primaryColor;
    if (adherence > 0.5) return const Color(0xFFFFB74D);
    if (adherence > 0) return AppTheme.errorColor;
    // adherence == 0: tüm dozlar kaçırıldı
    return AppTheme.errorColor.withValues(alpha: 0.55);
  }

  Color _textColor(
    double? adherence,
    bool isFuture,
    bool isToday,
    BuildContext context,
  ) {
    if (isFuture || adherence == null) {
      return isToday ? AppTheme.primaryColor : context.textLightClr;
    }
    if (adherence > 0.5) return Colors.white;
    if (adherence > 0) return Colors.white;
    return Colors.white.withValues(alpha: 0.85);
  }
}
