import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class CoachMarkStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;

  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class CoachMarkOverlay extends StatefulWidget {
  final List<CoachMarkStep> steps;
  final VoidCallback onComplete;
  final String nextLabel;
  final String finishLabel;
  final String stepOfLabel;

  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.nextLabel,
    required this.finishLabel,
    required this.stepOfLabel,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;

  late List<CoachMarkStep> _validSteps;

  @override
  void initState() {
    super.initState();
    _validSteps = _filterValidSteps();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (_validSteps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
    } else {
      _fadeController.forward();
    }
  }

  List<CoachMarkStep> _filterValidSteps() {
    return widget.steps.where((step) {
      final renderObj = step.targetKey.currentContext?.findRenderObject();
      return renderObj is RenderBox && renderObj.hasSize;
    }).toList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _validSteps.length - 1) {
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _currentStep++);
        _fadeController.forward();
      });
    } else {
      _fadeController.reverse().then((_) {
        if (mounted) widget.onComplete();
      });
    }
  }

  Rect? _getTargetRect(CoachMarkStep step) {
    final renderObj = step.targetKey.currentContext?.findRenderObject();
    if (renderObj is RenderBox && renderObj.hasSize) {
      final offset = renderObj.localToGlobal(Offset.zero);
      final size = renderObj.size;

      const minW = 64.0;
      const minH = 52.0;
      final padH = size.width < minW ? (minW - size.width) / 2 + 12 : 12.0;
      final padV = size.height < minH ? (minH - size.height) / 2 + 8 : 8.0;

      return Rect.fromLTWH(
        offset.dx - padH,
        offset.dy - padV,
        size.width + padH * 2,
        size.height + padV * 2,
      );
    }
    return null;
  }

  bool _showBelow(Rect targetRect, Size screenSize) {
    return targetRect.center.dy < screenSize.height * 0.45;
  }

  @override
  Widget build(BuildContext context) {
    if (_validSteps.isEmpty) return const SizedBox.shrink();

    final step = _validSteps[_currentStep];
    final targetRect = _getTargetRect(step);
    final screenSize = MediaQuery.of(context).size;
    final isLastStep = _currentStep == _validSteps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _next,
          child: Stack(
            children: [
              _PulseOverlay(
                controller: _pulseController,
                targetRect: targetRect,
                screenSize: screenSize,
              ),
              if (targetRect != null) _buildArrow(targetRect, screenSize),
              if (targetRect != null)
                _buildTooltip(context, step, targetRect, screenSize, isLastStep),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentStep + 1} ${widget.stepOfLabel} ${_validSteps.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow(Rect targetRect, Size screenSize) {
    final showBelow = _showBelow(targetRect, screenSize);
    final arrowX = targetRect.center.dx.clamp(40.0, screenSize.width - 40.0);
    final arrowY = showBelow ? targetRect.bottom + 2 : targetRect.top - 18;

    return Positioned(
      left: arrowX - 12,
      top: arrowY,
      child: CustomPaint(
        size: const Size(24, 16),
        painter: _ArrowPainter(
          pointUp: !showBelow,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkCardColor
              : Colors.white,
        ),
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    CoachMarkStep step,
    Rect targetRect,
    Size screenSize,
    bool isLastStep,
  ) {
    final showBelow = _showBelow(targetRect, screenSize);
    final tooltipTop = showBelow ? targetRect.bottom + 18 : null;
    final tooltipBottom =
        showBelow ? null : screenSize.height - targetRect.top + 18;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 20,
      right: 20,
      top: tooltipTop,
      bottom: tooltipBottom,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(step.icon, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  isLastStep ? widget.finishLabel : widget.nextLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseOverlay extends AnimatedWidget {
  final Rect? targetRect;
  final Size screenSize;

  const _PulseOverlay({
    required AnimationController controller,
    required this.targetRect,
    required this.screenSize,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final pulse = (listenable as AnimationController).value;
    return CustomPaint(
      size: screenSize,
      painter: _OverlayPainter(
        targetRect: targetRect,
        overlayColor: Colors.black.withValues(alpha: 0.72),
        glowOpacity: 0.4 + pulse * 0.6,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;
  final double glowOpacity;

  _OverlayPainter({
    this.targetRect,
    required this.overlayColor,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect != null) {
      final rrect = RRect.fromRectAndRadius(targetRect!, const Radius.circular(16));
      final path = Path()
        ..addRect(fullRect)
        ..addRRect(rrect)
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: glowOpacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(rrect, glowPaint);

      final outerGlowPaint = Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: glowOpacity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect!.inflate(4), const Radius.circular(20)),
        outerGlowPaint,
      );
    } else {
      canvas.drawRect(fullRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      glowOpacity != oldDelegate.glowOpacity;
}

class _ArrowPainter extends CustomPainter {
  final bool pointUp;
  final Color color;

  _ArrowPainter({required this.pointUp, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      pointUp != oldDelegate.pointUp || color != oldDelegate.color;
}
