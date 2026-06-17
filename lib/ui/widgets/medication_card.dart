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

  // İlaç başına renkli ikon paleti
  static const List<(Color, Color, IconData)> _palette = [
    (Color(0xFFE9F4F0), AppTheme.primaryColor, Icons.medication_rounded),
    (Color(0xFFFFF4E2), Color(0xFFF0A030), Icons.water_drop_rounded),
    (Color(0xFFEDEAFB), Color(0xFF7C6FE0), Icons.grain_rounded),
    (Color(0xFFE3F0FA), Color(0xFF3B8AD9), Icons.healing_rounded),
    (Color(0xFFEAF6F1), AppTheme.primaryColor, Icons.medication_liquid_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLowStock = medication.isLowStock;
    final (iconBg, iconFg, iconData) = isLowStock
        ? (const Color(0xFFFFECEC), AppTheme.accentColor, Icons.warning_amber_rounded)
        : _palette[medication.id.hashCode.abs() % _palette.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isLowStock
              ? Border.all(color: AppTheme.accentColor.withValues(alpha: 0.35), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.shadowAlpha),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(iconData, color: iconFg, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo(context, l10n)),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textLightClr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, AppLocalizations l10n) {
    final dosesText = medication.dosage.dosesPerDay == 1 ? l10n.dose : l10n.doses;
    final isLowStock = medication.isLowStock;
    final daysLeft = medication.estimatedDaysLeft;
    final unlimited = daysLeft >= 999;

    // Rozet metni
    final String badgeText;
    if (isLowStock) {
      badgeText = '${medication.currentStock} ${l10n.units} · $daysLeft ${l10n.daysLeftShort}';
    } else if (unlimited) {
      badgeText = '${medication.currentStock} ${l10n.units} · ${l10n.unlimited}';
    } else {
      badgeText = '${medication.currentStock} ${l10n.units} · $daysLeft ${l10n.daysShort}';
    }

    final badgeColor = isLowStock ? AppTheme.accentColor : AppTheme.primaryColor;
    final badgeBg = isLowStock
        ? const Color(0xFFFFECEC)
        : AppTheme.primaryColor.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medication.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryClr,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '${medication.dosage.pillsPerDose} ${l10n.pills} · ${l10n.daily} ${medication.dosage.dosesPerDay} $dosesText',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.textLightClr,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLowStock
                    ? Icons.warning_amber_rounded
                    : (unlimited ? Icons.all_inclusive_rounded : Icons.inventory_2_rounded),
                size: 14,
                color: badgeColor,
              ),
              const SizedBox(width: 5),
              Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
