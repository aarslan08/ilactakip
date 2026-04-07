import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/scheduled_dose.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

class SwipeDoseScreen extends StatefulWidget {
  const SwipeDoseScreen({super.key});

  @override
  State<SwipeDoseScreen> createState() => _SwipeDoseScreenState();
}

class _SwipeDoseScreenState extends State<SwipeDoseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _dragOffset = Offset.zero;
  double _rotation = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.medicationTime),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          final pendingDoses = provider.pendingDoses;

          if (pendingDoses.isEmpty) {
            return _buildAllDoneState();
          }

          return SafeArea(
            top: false,
            child: Column(
              children: [
                _buildProgress(provider),
                const SizedBox(height: 12),
                _buildSwipeHints(),
                Expanded(
                  child: Center(
                    child: _buildCardStack(pendingDoses),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildBottomButtons(pendingDoses.first),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgress(MedicationProvider provider) {
    final totalDoses = provider.todayScheduledDoses.length;
    final takenDoses = provider.takenDoses.length;
    final skippedDoses =
        provider.todayScheduledDoses.where((d) => d.isSkipped).length;
    final completedDoses = takenDoses + skippedDoses;
    final progress = totalDoses > 0 ? completedDoses / totalDoses : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.todaysProgress,
                style: TextStyle(fontSize: 13, color: context.textSecondaryClr),
              ),
              Text(
                '$completedDoses / $totalDoses',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.dividerClr,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeHints() {
    final dragX = _dragOffset.dx;
    final skipOpacity = dragX < -10 ? math.min(1.0, dragX.abs() / 100) : 0.4;
    final takenOpacity = dragX > 10 ? math.min(1.0, dragX / 100) : 0.4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedOpacity(
            opacity: skipOpacity,
            duration: const Duration(milliseconds: 100),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded, color: AppTheme.errorColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  l10n.skip.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: takenOpacity,
            duration: const Duration(milliseconds: 100),
            child: Row(
              children: [
                Text(
                  l10n.taken.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.successColor, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(List<ScheduledDose> doses) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (int i = math.min(2, doses.length - 1); i > 0; i--)
          Transform.translate(
            offset: Offset(0, i * 8.0),
            child: Transform.scale(
              scale: 1 - (i * 0.04),
              child: Opacity(
                opacity: 1 - (i * 0.15),
                child: _buildCard(doses[i], isTop: false),
              ),
            ),
          ),
        if (doses.isNotEmpty)
          GestureDetector(
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: (details) {
              setState(() {
                _dragOffset += details.delta;
                _rotation = _dragOffset.dx / 300;
              });
            },
            onPanEnd: (_) => _handleSwipeEnd(doses.first),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final matrix = Matrix4.identity()
                  ..setEntry(0, 3, _dragOffset.dx)
                  ..setEntry(1, 3, _dragOffset.dy)
                  ..rotateZ(_rotation * 0.3);
                return Transform(
                  alignment: Alignment.center,
                  transform: matrix,
                  child: _buildCard(
                    doses.first,
                    isTop: true,
                    showOverlay: _isDragging,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCard(ScheduledDose dose, {bool isTop = false, bool showOverlay = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final medication = dose.medication;

    Color? overlayColor;
    IconData? overlayIcon;
    String? overlayText;

    if (showOverlay && _dragOffset.dx.abs() > 30) {
      if (_dragOffset.dx > 0) {
        overlayColor = AppTheme.successColor;
        overlayIcon = Icons.check_rounded;
        overlayText = l10n.taken.toUpperCase();
      } else {
        overlayColor = AppTheme.errorColor;
        overlayIcon = Icons.close_rounded;
        overlayText = l10n.skip.toUpperCase();
      }
    }

    return Container(
      width: screenWidth * 0.88,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha * 1.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İlaç ikonu
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 20),

              // İlaç adı
              Text(
                medication.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryClr,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Saat badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      dose.scheduledTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Aç/Tok bilgisi
              if (medication.intakeType != IntakeType.either) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getIntakeTypeColor(medication.intakeType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getIntakeTypeColor(medication.intakeType).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(medication.intakeType.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        _getIntakeTypeName(medication.intakeType),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getIntakeTypeColor(medication.intakeType),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Bilgi chip'leri
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.medication_outlined,
                    label: '${medication.dosage.pillsPerDose} ${l10n.pills}',
                  ),
                  _buildInfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${medication.currentStock} ${l10n.remaining}',
                    isWarning: medication.isLowStock,
                  ),
                ],
              ),

              // Gecikti uyarısı
              if (dose.isPastDue) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l10n.overdue,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          ),

          // Swipe overlay
          if (overlayColor != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: overlayColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(overlayIcon, color: Colors.white, size: 72),
                    const SizedBox(height: 12),
                    Text(
                      overlayText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.warningColor.withValues(alpha: 0.1)
            : context.subtleBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isWarning ? AppTheme.warningColor : context.textSecondaryClr,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isWarning ? AppTheme.warningColor : context.textSecondaryClr,
              fontWeight: isWarning ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ScheduledDose dose) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          icon: Icons.close_rounded,
          color: AppTheme.errorColor,
          onTap: () => _handleSkip(dose),
          size: 62,
        ),
        const SizedBox(width: 48),
        _buildCircleButton(
          icon: Icons.check_rounded,
          color: AppTheme.successColor,
          onTap: () => _handleTake(dose),
          size: 72,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  Color _getIntakeTypeColor(IntakeType type) {
    switch (type) {
      case IntakeType.empty:
        return Colors.orange;
      case IntakeType.full:
        return Colors.green;
      case IntakeType.either:
        return AppTheme.primaryColor;
    }
  }

  String _getIntakeTypeName(IntakeType type) {
    switch (type) {
      case IntakeType.empty:
        return l10n.onEmptyStomach;
      case IntakeType.full:
        return l10n.onFullStomach;
      case IntakeType.either:
        return l10n.anytime;
    }
  }

  Widget _buildAllDoneState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: AppTheme.successColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${l10n.allDone} 🎉',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryClr,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.allDosesTaken,
              style: TextStyle(
                fontSize: 16,
                color: context.textSecondaryClr,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.backToHome),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSwipeEnd(ScheduledDose dose) {
    final threshold = MediaQuery.of(context).size.width * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      if (_dragOffset.dx > 0) {
        _handleTake(dose);
      } else {
        _handleSkip(dose);
      }
    }

    _resetCard();
  }

  void _handleTake(ScheduledDose dose) async {
    final provider = context.read<MedicationProvider>();
    final success = await provider.takeDose(dose);

    if (success && mounted) {
      _showFeedback(
        message: '${dose.medication.name} ${l10n.markedAsTaken}',
        color: AppTheme.successColor,
        icon: Icons.check_circle_rounded,
      );
    }

    _resetCard();
  }

  void _handleSkip(ScheduledDose dose) async {
    final provider = context.read<MedicationProvider>();
    await provider.skipDose(dose);

    if (mounted) {
      _showFeedback(
        message: '${dose.medication.name} ${l10n.wasSkipped}',
        color: AppTheme.textSecondary,
        icon: Icons.skip_next_rounded,
      );
    }

    _resetCard();
  }

  void _showFeedback({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _isDragging = false;
    });
  }
}
