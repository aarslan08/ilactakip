import 'package:flutter/material.dart';
import 'package:ilac_takip/models/scheduled_dose.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              _buildTimeSection(),
              const SizedBox(width: 10),
              
              // Orta - İlaç bilgisi
              Expanded(child: _buildInfoSection()),
              
              const SizedBox(width: 8),
              
              // Sağ taraf - Aksiyon butonları
              if (scheduledDose.isPending) _buildActionButtons(),
              if (!scheduledDose.isPending) _buildStatusBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
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
            const Text(
              'Gecikti',
              style: TextStyle(
                fontSize: 9,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Aç/Tok badge
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
                  medication.intakeType.shortName,
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
          '${medication.dosage.pillsPerDose} adet • ${medication.currentStock} kaldı',
          style: TextStyle(
            fontSize: 12,
            color: medication.isLowStock
                ? AppTheme.warningColor
                : AppTheme.textSecondary,
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

  Widget _buildActionButtons() {
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
              child: const Icon(
                Icons.skip_next_rounded,
                color: AppTheme.textSecondary,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Aldım',
                    style: TextStyle(
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

  Widget _buildStatusBadge() {
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
            scheduledDose.statusText,
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

  Color _getBackgroundColor() {
    if (scheduledDose.isTaken) return AppTheme.takenColor.withValues(alpha: 0.05);
    if (scheduledDose.isMissed) return AppTheme.missedColor.withValues(alpha: 0.05);
    if (scheduledDose.isSkipped) return AppTheme.skippedColor.withValues(alpha: 0.05);
    if (scheduledDose.isPastDue) return AppTheme.warningColor.withValues(alpha: 0.05);
    return Colors.white;
  }

  Color _getBorderColor() {
    if (scheduledDose.isTaken) return AppTheme.takenColor.withValues(alpha: 0.3);
    if (scheduledDose.isMissed) return AppTheme.missedColor.withValues(alpha: 0.3);
    if (scheduledDose.isSkipped) return AppTheme.skippedColor.withValues(alpha: 0.3);
    if (scheduledDose.isPastDue) return AppTheme.warningColor.withValues(alpha: 0.5);
    return Colors.grey.shade200;
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
