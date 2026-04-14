import 'package:flutter/material.dart';
import 'package:ilac_takip/models/scheduled_dose.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/models/dosage.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

/// Tek bir doz kartı widget'ı
class DoseCard extends StatelessWidget {
  final ScheduledDose scheduledDose;
  final VoidCallback? onTake;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  const DoseCard({
    super.key,
    required this.scheduledDose,
    this.onTake,
    this.onSkip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(context),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.shadowAlpha),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Sol taraf - Saat
              _buildTimeSection(l10n),
              const SizedBox(width: 10),
              
              // Orta - İlaç bilgisi
              Expanded(child: _buildInfoSection(context, l10n)),
              
              const SizedBox(width: 8),
              
              // Sağ taraf - Aksiyon butonları
              if (scheduledDose.isPending) _buildActionButtons(context, l10n),
              if (!scheduledDose.isPending) _buildStatusBadge(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getTimeBackgroundColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scheduledDose.scheduledTime,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _getTimeTextColor(),
            ),
          ),
          if (scheduledDose.isPastDue && scheduledDose.isPending)
            Text(
              l10n.overdue,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, AppLocalizations l10n) {
    final medication = scheduledDose.medication;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                medication.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryClr,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (medication.dosage.frequencyType != FrequencyType.daily) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  medication.dosage.frequencyType == FrequencyType.weekly
                      ? l10n.frequencyWeekly
                      : l10n.frequencyMonthly,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
            if (medication.intakeType != IntakeType.either) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: medication.intakeType == IntakeType.empty
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getIntakeTypeShortName(medication.intakeType, l10n),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: medication.intakeType == IntakeType.empty
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${medication.dosage.pillsPerDose} ${l10n.pills} • ${medication.currentStock} ${l10n.remaining}',
          style: TextStyle(
            fontSize: 12,
            color: medication.isLowStock
                ? AppTheme.warningColor
                : context.textSecondaryClr,
            fontWeight: medication.isLowStock
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getIntakeTypeShortName(IntakeType type, AppLocalizations l10n) {
    switch (type) {
      case IntakeType.empty:
        return l10n.empty;
      case IntakeType.full:
        return l10n.full;
      case IntakeType.either:
        return l10n.anytime;
    }
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Atla butonu
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSkip,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.skip_next_rounded,
                color: context.textSecondaryClr,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Aldım butonu
        Material(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTake,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.taken,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 3),
          Text(
            _getStatusText(l10n),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AppLocalizations l10n) {
    if (scheduledDose.isTaken) return l10n.takenStatus;
    if (scheduledDose.isMissed) return l10n.missedStatus;
    if (scheduledDose.isSkipped) return l10n.skippedStatus;
    return l10n.pendingStatus;
  }

  Color _getBackgroundColor(BuildContext context) {
    if (scheduledDose.isTaken) return AppTheme.takenColor.withValues(alpha: 0.05);
    if (scheduledDose.isMissed) return AppTheme.missedColor.withValues(alpha: 0.05);
    if (scheduledDose.isSkipped) return AppTheme.skippedColor.withValues(alpha: 0.05);
    if (scheduledDose.isPastDue) return AppTheme.warningColor.withValues(alpha: 0.05);
    return context.cardBg;
  }

  Color _getBorderColor(BuildContext context) {
    if (scheduledDose.isTaken) return AppTheme.takenColor.withValues(alpha: 0.3);
    if (scheduledDose.isMissed) return AppTheme.missedColor.withValues(alpha: 0.3);
    if (scheduledDose.isSkipped) return AppTheme.skippedColor.withValues(alpha: 0.3);
    if (scheduledDose.isPastDue) return AppTheme.warningColor.withValues(alpha: 0.5);
    return context.dividerClr;
  }

  Color _getTimeBackgroundColor() {
    if (scheduledDose.isPastDue && scheduledDose.isPending) {
      return AppTheme.warningColor.withValues(alpha: 0.15);
    }
    return AppTheme.primaryColor.withValues(alpha: 0.1);
  }

  Color _getTimeTextColor() {
    if (scheduledDose.isPastDue && scheduledDose.isPending) {
      return AppTheme.warningColor;
    }
    return AppTheme.primaryColor;
  }

  Color _getStatusColor() {
    if (scheduledDose.isTaken) return AppTheme.takenColor;
    if (scheduledDose.isMissed) return AppTheme.missedColor;
    if (scheduledDose.isSkipped) return AppTheme.skippedColor;
    return AppTheme.pendingColor;
  }

  IconData _getStatusIcon() {
    if (scheduledDose.isTaken) return Icons.check_circle_rounded;
    if (scheduledDose.isMissed) return Icons.cancel_rounded;
    if (scheduledDose.isSkipped) return Icons.skip_next_rounded;
    return Icons.schedule_rounded;
  }
}
