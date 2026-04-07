import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';
import 'package:ilac_takip/ui/screens/medication_detail_screen.dart';
import 'package:ilac_takip/ui/screens/swipe_dose_screen.dart';
import 'package:ilac_takip/ui/screens/statistics_screen.dart';

/// Ana ekran - Bugünkü dozlar
class HomeScreen extends StatefulWidget {
  final GlobalKey? statsCardKey;
  final GlobalKey? dosesCardKey;
  final GlobalKey? quickActionKey;
  final GlobalKey? scheduleKey;

  const HomeScreen({
    super.key,
    this.statsCardKey,
    this.dosesCardKey,
    this.quickActionKey,
    this.scheduleKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _reminderShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MedicationProvider>();
      await provider.loadData();
      if (mounted) _checkPendingDoses(provider);
    });
  }

  void _checkPendingDoses(MedicationProvider provider) {
    if (_reminderShown) return;

    final pastDue = provider.todayScheduledDoses.where((d) => d.isPastDue).toList();
    final pending = provider.pendingDoses;

    if (pastDue.isNotEmpty || pending.length >= 2) {
      _reminderShown = true;
      _showPendingDosesSheet(pastDue.length, pending.length);
    }
  }

  void _showPendingDosesSheet(int pastDueCount, int pendingCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerClr,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: pastDueCount > 0
                      ? [AppTheme.errorColor.withValues(alpha: 0.12), AppTheme.warningColor.withValues(alpha: 0.08)]
                      : [AppTheme.primaryColor.withValues(alpha: 0.12), AppTheme.primaryLight.withValues(alpha: 0.08)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pastDueCount > 0
                          ? AppTheme.errorColor.withValues(alpha: 0.15)
                          : AppTheme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      pastDueCount > 0 ? Icons.alarm_rounded : Icons.medication_rounded,
                      color: pastDueCount > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pendingDosesReminder,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryClr,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.pendingDosesReminderDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryClr,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Doz sayıları
            Row(
              children: [
                if (pastDueCount > 0)
                  Expanded(
                    child: _buildDoseCountChip(
                      count: pastDueCount,
                      label: l10n.pastDueDoses,
                      color: AppTheme.errorColor,
                      icon: Icons.warning_rounded,
                    ),
                  ),
                if (pastDueCount > 0 && pendingCount - pastDueCount > 0)
                  const SizedBox(width: 10),
                if (pendingCount - pastDueCount > 0)
                  Expanded(
                    child: _buildDoseCountChip(
                      count: pendingCount - pastDueCount,
                      label: l10n.pendingDoses,
                      color: AppTheme.warningColor,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textSecondaryClr,
                      side: BorderSide(color: context.dividerClr),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n.later,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToSwipeDose();
                    },
                    icon: const Icon(Icons.swipe_rounded, size: 20),
                    label: Text(
                      l10n.takeNow,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pastDueCount > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseCountChip({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Consumer<MedicationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.medications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            }

            if (!provider.hasMedications) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadData(),
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader(provider)),
                  
                  // İstatistikler
                  SliverToBoxAdapter(child: _buildStats(provider)),
                  
                  // Hızlı İlaç Al butonu
                  if (provider.pendingDoses.isNotEmpty)
                    SliverToBoxAdapter(child: _buildQuickActionButton(provider)),
                  
                  // Uyarılar
                  if (provider.lowStockMedications.isNotEmpty)
                    SliverToBoxAdapter(child: _buildWarnings(provider)),
                  
                  // Bugünkü dozlar başlığı
                  SliverToBoxAdapter(child: _buildSectionHeader()),
                  
                  // Doz listesi
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: _buildDoseList(provider),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.medication_liquid_outlined,
      title: l10n.noMedications,
      subtitle: l10n.addFirstMedication,
      buttonText: l10n.addMedication,
      onButtonPressed: () => _navigateToAddMedication(),
    );
  }

  Widget _buildHeader(MedicationProvider provider) {
    final now = DateTime.now();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textSecondaryClr,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.isToday(now)
                          ? l10n.today
                          : AppDateUtils.formatDate(now),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryClr,
                      ),
                    ),
                    Text(
                      AppDateUtils.formatWeekday(now),
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textSecondaryClr,
                      ),
                    ),
                  ],
                ),
              ),
              // Profil avatarı
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(MedicationProvider provider) {
    final totalDoses = provider.todayScheduledDoses.length;
    final takenDoses = provider.takenDoses.length;
    final adherencePercent = (provider.todayAdherenceRate * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              key: widget.dosesCardKey,
              title: l10n.todaysDoses,
              value: '$takenDoses/$totalDoses',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              key: widget.statsCardKey,
              title: l10n.adherenceRate,
              value: '%$adherencePercent',
              icon: Icons.trending_up_rounded,
              color: adherencePercent >= 80
                  ? AppTheme.successColor
                  : adherencePercent >= 50
                      ? AppTheme.warningColor
                      : AppTheme.errorColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(MedicationProvider provider) {
    final pendingCount = provider.pendingDoses.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => _navigateToSwipeDose(),
        child: Container(
          key: widget.quickActionKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swipe_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.medicationTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingCount ${l10n.pendingDoses}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.start,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarnings(MedicationProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.warningColor.withValues(alpha: 0.1),
              AppTheme.warningColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.warningColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lowStockWarning,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryClr,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${provider.lowStockMedications.length} ${l10n.medicationsLowStock}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryClr,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.warningColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      key: widget.scheduleKey,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            l10n.todaysSchedule,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryClr,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Tümünü gör
            },
            child: Text(l10n.viewAll),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseList(MedicationProvider provider) {
    final doses = provider.todayScheduledDoses;

    if (doses.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noDosesScheduled,
                style: TextStyle(
                  fontSize: 16,
                  color: context.textSecondaryClr,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dose = doses[index];
          return DoseCard(
            scheduledDose: dose,
            onTake: () => _handleTakeDose(dose),
            onSkip: () => _handleSkipDose(dose),
            onTap: () => _navigateToMedicationDetail(dose.medication.id),
          );
        },
        childCount: doses.length,
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddMedication(),
      icon: const Icon(Icons.add_rounded),
      label: Text(l10n.addMedication),
      backgroundColor: AppTheme.primaryColor,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return l10n.goodNight;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  void _handleTakeDose(scheduledDose) async {
    final provider = context.read<MedicationProvider>();
    final success = await provider.takeDose(scheduledDose);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${scheduledDose.medication.name} ${l10n.markedAsTaken}'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _handleSkipDose(scheduledDose) async {
    final provider = context.read<MedicationProvider>();
    await provider.skipDose(scheduledDose);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.skip_next, color: Colors.white),
              const SizedBox(width: 8),
              Text('${scheduledDose.medication.name} ${l10n.wasSkipped}'),
            ],
          ),
          backgroundColor: context.textSecondaryClr,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _navigateToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  void _navigateToMedicationDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicationDetailScreen(medicationId: id)),
    );
  }

  void _navigateToSwipeDose() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SwipeDoseScreen()),
    );
  }
}
