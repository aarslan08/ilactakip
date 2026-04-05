import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isWeekly = true;
  bool _isLoading = true;

  Map<DateTime, double> _adherenceData = {};
  List<({Medication medication, double adherenceRate, int taken, int total})> _breakdown = [];
  ({int totalTaken, int totalMissed, int totalSkipped, double overallRate}) _summary =
      (totalTaken: 0, totalMissed: 0, totalSkipped: 0, overallRate: 0.0);

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final provider = context.read<MedicationProvider>();
    final days = _isWeekly ? 7 : 30;

    final adherence = _isWeekly
        ? await provider.getWeeklyAdherence()
        : await provider.getMonthlyAdherence();
    final breakdown = await provider.getMedicationAdherenceBreakdown(days: days);
    final summary = await provider.getRangeSummary(days: days);

    if (mounted) {
      setState(() {
        _adherenceData = adherence;
        _breakdown = breakdown;
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildOverallCard(),
                  const SizedBox(height: 20),
                  _buildToggle(),
                  const SizedBox(height: 20),
                  _buildChartCard(),
                  const SizedBox(height: 20),
                  _buildSummaryRow(),
                  const SizedBox(height: 20),
                  _buildBreakdownSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallCard() {
    final percent = (_summary.overallRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.overallAdherence,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '%$percent',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_isWeekly ? l10n.weeklyView : l10n.monthlyView} — ${_summary.totalTaken + _summary.totalMissed + _summary.totalSkipped} ${l10n.dosesCount}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToggleButton(l10n.weeklyView, _isWeekly, () {
            if (!_isWeekly) {
              setState(() => _isWeekly = true);
              _loadData();
            }
          }),
          _buildToggleButton(l10n.monthlyView, !_isWeekly, () {
            if (_isWeekly) {
              setState(() => _isWeekly = false);
              _loadData();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : context.textSecondaryClr,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adherenceRate,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryClr,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _isWeekly ? _buildBarChart() : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '%${rod.toY.round()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 50 || value == 100) {
                  return Text(
                    '%${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: context.textLightClr),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                final day = days[idx];
                final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                final enDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final locale = Localizations.localeOf(context).languageCode;
                final names = locale == 'tr' ? dayNames : enDayNames;
                return Text(
                  names[day.weekday - 1],
                  style: TextStyle(fontSize: 11, color: context.textSecondaryClr),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.dividerClr,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: days.asMap().entries.map((entry) {
          final rate = (_adherenceData[entry.value] ?? 0.0) * 100;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: rate,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: [
                    _getBarColor(rate),
                    _getBarColor(rate).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    final now = DateTime.now();
    final days = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final spots = days.asMap().entries.map((entry) {
      final rate = (_adherenceData[entry.value] ?? 0.0) * 100;
      return FlSpot(entry.key.toDouble(), rate);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '%${spot.y.round()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 50 || value == 100) {
                  return Text(
                    '%${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: context.textLightClr),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                final day = days[idx];
                return Text(
                  '${day.day}/${day.month}',
                  style: TextStyle(fontSize: 10, color: context.textSecondaryClr),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.dividerClr,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            l10n.totalDosesTaken,
            '${_summary.totalTaken}',
            AppTheme.successColor,
            Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryItem(
            l10n.totalDosesMissed,
            '${_summary.totalMissed}',
            AppTheme.errorColor,
            Icons.cancel_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryItem(
            l10n.totalDosesSkipped,
            '${_summary.totalSkipped}',
            AppTheme.skippedColor,
            Icons.skip_next_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.primaryAlpha),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryClr,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondaryClr,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adherenceByMedication,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryClr,
          ),
        ),
        const SizedBox(height: 12),
        if (_breakdown.isEmpty || _breakdown.every((b) => b.total == 0))
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                l10n.noDataYet,
                style: TextStyle(color: context.textSecondaryClr),
              ),
            ),
          )
        else
          ...(_breakdown.where((b) => b.total > 0).map(_buildBreakdownItem)),
      ],
    );
  }

  Widget _buildBreakdownItem(
    ({Medication medication, double adherenceRate, int taken, int total}) item,
  ) {
    final percent = (item.adherenceRate * 100).round();
    final color = _getBarColor(percent.toDouble());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                      AppTheme.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.medication.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryClr,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.taken}/${item.total} ${l10n.dosesCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryClr,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '%$percent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.adherenceRate,
              minHeight: 8,
              backgroundColor: context.dividerClr,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(double percent) {
    if (percent >= 80) return AppTheme.successColor;
    if (percent >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
