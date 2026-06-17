import 'package:flutter/material.dart';
import 'package:ilac_takip/models/scheduled_dose.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/screens/swipe_dose_screen.dart';
import 'package:ilac_takip/ui/screens/main_navigation.dart';

/// Uygulama açılışında birden fazla pending doz varsa gösterilen
/// hızlı başlangıç ekranı. Kullanıcı istediği ilacı seçerek başlar.
class QuickStartScreen extends StatelessWidget {
  final List<ScheduledDose> pendingDoses;

  const QuickStartScreen({
    super.key,
    required this.pendingDoses,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildHeader(context, l10n),
              const SizedBox(height: 32),
              Expanded(child: _buildDoseList(context, l10n)),
              const SizedBox(height: 16),
              _buildHomeButton(context, l10n),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.medication_rounded,
            color: AppTheme.primaryColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.quickStartTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryClr,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.quickStartSubtitle,
          style: TextStyle(
            fontSize: 16,
            color: context.textSecondaryClr,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDoseList(BuildContext context, AppLocalizations l10n) {
    return ListView.separated(
      itemCount: pendingDoses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dose = pendingDoses[index];
        return _buildDoseCard(context, l10n, dose);
      },
    );
  }

  Widget _buildDoseCard(
    BuildContext context,
    AppLocalizations l10n,
    ScheduledDose dose,
  ) {
    final medication = dose.medication;
    final isPastDue = dose.isPastDue;

    return GestureDetector(
      onTap: () => _navigateToSwipeDose(context, dose.medication.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPastDue
                ? AppTheme.warningColor.withValues(alpha: 0.5)
                : context.dividerClr,
            width: isPastDue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.shadowAlpha),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.medication_rounded,
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
                    medication.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryClr,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosage.pillsPerDose} ${l10n.pills}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryClr,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPastDue
                        ? AppTheme.warningColor.withValues(alpha: 0.15)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dose.scheduledTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPastDue
                          ? AppTheme.warningColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (isPastDue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.overdue,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textLightClr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _navigateToHome(context),
        icon: const Icon(Icons.home_rounded),
        label: Text(l10n.goToHome),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _navigateToSwipeDose(BuildContext context, String medicationId) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SwipeDoseScreen(initialMedicationId: medicationId),
      ),
      (route) => false,
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }
}
