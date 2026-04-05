import 'package:flutter/material.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

/// İlaç kartı widget'ı
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.shadowAlpha),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Üst kısım - Ana bilgiler
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // İlaç ikonu
                  _buildIcon(),
                  const SizedBox(width: 16),
                  
                  // İlaç bilgileri
                  Expanded(child: _buildInfo(context, l10n)),
                  
                  // Ok ikonu
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.textLightClr,
                  ),
                ],
              ),
            ),
            
            // Alt kısım - Stok ve uyarılar
            _buildBottomSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.medication_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildInfo(BuildContext context, AppLocalizations l10n) {
    final dosesText = medication.dosage.dosesPerDay == 1 ? l10n.dose : l10n.doses;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medication.name,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryClr,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${medication.dosage.pillsPerDose} ${l10n.pills} × ${l10n.daily} ${medication.dosage.dosesPerDay} $dosesText',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondaryClr,
          ),
        ),
        if (medication.dosage.scheduleTimes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            medication.dosage.scheduleTimes.join(' • '),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBottomSectionColor(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Stok bilgisi
          _buildStockInfo(context, l10n),
          const Spacer(),
          // Kalan gün bilgisi
          _buildDaysLeftInfo(context, l10n),
        ],
      ),
    );
  }

  Widget _buildStockInfo(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: medication.isLowStock ? AppTheme.warningColor : context.textSecondaryClr,
        ),
        const SizedBox(width: 6),
        Text(
          '${medication.currentStock} ${l10n.units}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: medication.isLowStock ? AppTheme.warningColor : context.textPrimaryClr,
          ),
        ),
        if (medication.isLowStock) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.lowStock,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDaysLeftInfo(BuildContext context, AppLocalizations l10n) {
    final daysLeft = medication.estimatedDaysLeft;
    final isLow = daysLeft <= medication.firstRunoutWarningDays;
    
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: isLow ? AppTheme.accentColor : context.textSecondaryClr,
        ),
        const SizedBox(width: 6),
        Text(
          daysLeft >= 999 ? '∞' : '~$daysLeft ${l10n.daysRemaining}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isLow ? AppTheme.accentColor : context.textSecondaryClr,
          ),
        ),
      ],
    );
  }

  Color _getBottomSectionColor(BuildContext context) {
    if (medication.isOutOfStock) return AppTheme.errorColor.withValues(alpha: 0.08);
    if (medication.isCriticalStock) return AppTheme.accentColor.withValues(alpha: 0.08);
    if (medication.isLowStock) return AppTheme.warningColor.withValues(alpha: 0.08);
    return context.scaffoldBg;
  }
}
