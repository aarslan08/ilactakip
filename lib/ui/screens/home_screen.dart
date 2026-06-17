import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/scheduled_dose.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';
import 'package:ilac_takip/ui/screens/medication_detail_screen.dart';
import 'package:ilac_takip/ui/screens/swipe_dose_screen.dart';
import 'package:ilac_takip/ui/screens/statistics_screen.dart';
import 'package:ilac_takip/ui/screens/logs_screen.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MedicationProvider>();
      await provider.loadData();
      await provider.rescheduleAllNotifications();
    });
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
    final progress = totalDoses > 0 ? takenDoses / totalDoses : 0.0;
    final streak = provider.currentStreak;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        key: widget.dosesCardKey,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.shadowAlpha),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              // Dairesel ilerleme halkası
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$takenDoses/$totalDoses',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryClr,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.dosesTaken,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryClr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              // Uyum + seri
              Expanded(
                child: Column(
                  key: widget.statsCardKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todaysAdherence,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryClr,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '%$adherencePercent',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: context.dividerClr),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$streak',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimaryClr,
                                ),
                              ),
                              TextSpan(
                                text: ' ${l10n.dayStreak}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondaryClr,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(MedicationProvider provider) {
    final pendingCount = provider.pendingDoses.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => _navigateToSwipeDose(initialMedicationId: null),
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
            onPressed: () => _navigateToLogs(),
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
          return _buildTimelineDose(
            provider,
            dose,
            isLast: index == doses.length - 1,
          );
        },
        childCount: doses.length,
      ),
    );
  }

  // İlaç başına renkli ikon paleti (görsel çeşitlilik için)
  static const List<(Color, Color, IconData)> _iconPalette = [
    (Color(0xFFE9F4F0), AppTheme.primaryColor, Icons.medication_rounded),
    (Color(0xFFFFF4E2), Color(0xFFF0A030), Icons.water_drop_rounded),
    (Color(0xFFEDEAFB), Color(0xFF7C6FE0), Icons.grain_rounded),
    (Color(0xFFE3F0FA), Color(0xFF3B8AD9), Icons.healing_rounded),
    (Color(0xFFEAF6F1), AppTheme.primaryColor, Icons.medication_liquid_rounded),
  ];

  (Color, Color, IconData) _paletteFor(String medId) {
    return _iconPalette[medId.hashCode.abs() % _iconPalette.length];
  }

  Widget _buildTimelineDose(
    MedicationProvider provider,
    ScheduledDose dose, {
    required bool isLast,
  }) {
    final medication = dose.medication;
    final isDone = !dose.isPending;
    final isPastDue = dose.isPending && dose.isPastDue;

    // Zaman çizelgesi nokta rengi
    final Color dotColor;
    final Color dotBorder;
    if (isDone) {
      dotColor = AppTheme.primaryColor;
      dotBorder = AppTheme.primaryColor;
    } else if (isPastDue) {
      dotColor = context.cardBg;
      dotBorder = AppTheme.warningColor;
    } else {
      dotColor = context.cardBg;
      dotBorder = context.dividerClr;
    }

    final (iconBg, iconFg, iconData) = isDone
        ? (AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor, Icons.medication_rounded)
        : _paletteFor(medication.id);

    final timeFaded = !isDone && !isPastDue;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saat sütunu
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                dose.scheduledTime,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: timeFaded ? context.textLightClr : context.textPrimaryClr,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Zaman çizelgesi nokta + çizgi
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotBorder, width: 3),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.dividerClr,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Doz kartı
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => dose.isPending
                    ? _navigateToSwipeDose(initialMedicationId: medication.id)
                    : _navigateToMedicationDetail(medication.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: isPastDue
                        ? Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.shadowAlpha),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(iconData, size: 22, color: iconFg),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryClr,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${medication.dosage.pillsPerDose} ${l10n.pills}'
                              '${medication.intakeType != IntakeType.either ? ' · ${medication.intakeType.icon}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.textLightClr,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildDoseTrailing(provider, dose),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseTrailing(MedicationProvider provider, ScheduledDose dose) {
    if (dose.isTaken) {
      return const Icon(Icons.check_circle_rounded, size: 28, color: AppTheme.primaryColor);
    }
    if (dose.isMissed) {
      return const Icon(Icons.cancel_rounded, size: 26, color: AppTheme.errorColor);
    }
    if (dose.isSkipped) {
      return Icon(Icons.skip_next_rounded, size: 26, color: context.textLightClr);
    }
    // Pending → "Al" butonu
    return GestureDetector(
      onTap: () => provider.takeDose(dose),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.take,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
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

  void _navigateToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  void _navigateToLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogsScreen()),
    );
  }

  void _navigateToMedicationDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicationDetailScreen(medicationId: id)),
    );
  }

  void _navigateToSwipeDose({String? initialMedicationId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SwipeDoseScreen(initialMedicationId: initialMedicationId),
      ),
    );
  }
}
