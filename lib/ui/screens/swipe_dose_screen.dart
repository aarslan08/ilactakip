import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/scheduled_dose.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

/// Tinder tarzı ilaç alma ekranı
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

          return Column(
            children: [
              // Progress göstergesi
              _buildProgress(provider),
              const SizedBox(height: 20),

              // Swipe talimatları
              _buildSwipeHints(),
              const SizedBox(height: 20),

              // Kart stack
              Expanded(
                child: _buildCardStack(pendingDoses),
              ),

              // Alt butonlar
              SafeArea(
                top: false,
                child: _buildBottomButtons(pendingDoses.first),
              ),
              const SizedBox(height: 16),
            ],
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
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondaryClr,
                ),
              ),
              Text(
                '$completedDoses / $totalDoses',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.dividerClr,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeHints() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sola kaydır - Atla
          Row(
            children: [
              Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.errorColor.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.skip,
                style: TextStyle(
                  color: AppTheme.errorColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Sağa kaydır - Aldım
          Row(
            children: [
              Text(
                l10n.taken,
                style: TextStyle(
                  color: AppTheme.successColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.successColor.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(List<ScheduledDose> doses) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Arkadaki kartlar (max 2 tane göster)
        for (int i = math.min(2, doses.length - 1); i > 0; i--)
          Positioned(
            top: i * 10.0,
            child: Transform.scale(
              scale: 1 - (i * 0.05),
              child: Opacity(
                opacity: 1 - (i * 0.2),
                child: _buildCard(doses[i], isTop: false),
              ),
            ),
          ),

        // En üstteki kart (sürüklenebilir)
        if (doses.isNotEmpty)
          GestureDetector(
            onPanStart: (_) {
              setState(() => _isDragging = true);
            },
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
    final screenHeight = MediaQuery.of(context).size.height;
    final medication = dose.medication;
    
    // Dinamik kart yüksekliği - ekran boyutuna göre
    final cardHeight = math.min(380.0, screenHeight * 0.45);
    
    // Overlay renkleri
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
      width: screenWidth * 0.85,
      height: cardHeight,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Kart içeriği - SingleChildScrollView ile taşmayı önle
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İlaç ikonu
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // İlaç adı
                  Text(
                    medication.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryClr,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Saat
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dose.scheduledTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Aç/Tok bilgisi
                  if (medication.intakeType != IntakeType.either)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getIntakeTypeColor(medication.intakeType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getIntakeTypeColor(medication.intakeType)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            medication.intakeType.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
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
                  if (medication.intakeType != IntakeType.either)
                    const SizedBox(height: 12),

                  // Dozaj bilgisi
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        context,
                        icon: Icons.medication_outlined,
                        label: '${medication.dosage.pillsPerDose} ${l10n.pills}',
                      ),
                      _buildInfoChip(
                        context,
                        icon: Icons.inventory_2_outlined,
                        label: '${medication.currentStock} ${l10n.remaining}',
                        isWarning: medication.isLowStock,
                      ),
                    ],
                  ),

                  // Gecikti uyarısı
                  if (dose.isPastDue) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.warningColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.overdue,
                            style: const TextStyle(
                              fontSize: 13,
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
          ),

          // Swipe overlay
          if (overlayColor != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: overlayColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      overlayIcon,
                      color: Colors.white,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      overlayText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
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

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.warningColor.withValues(alpha: 0.1)
            : context.subtleBg,
        borderRadius: BorderRadius.circular(20),
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
              fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
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

  Widget _buildBottomButtons(ScheduledDose dose) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Atla butonu
          _buildCircleButton(
            icon: Icons.close_rounded,
            color: AppTheme.errorColor,
            onTap: () => _handleSkip(dose),
            size: 64,
          ),
          // Aldım butonu
          _buildCircleButton(
            icon: Icons.check_rounded,
            color: AppTheme.successColor,
            onTap: () => _handleTake(dose),
            size: 80,
          ),
        ],
      ),
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
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
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

    // Reset
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _isDragging = false;
    });
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
