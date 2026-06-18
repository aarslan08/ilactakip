import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _entranceCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _crossCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _dotPulseCtrl;

  // Entrance animations
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconRotation;
  late final Animation<double> _glassRingScale;
  late final Animation<double> _glassRingOpacity;
  late final Animation<double> _pillOpacity;
  late final Animation<double> _pillDash;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _dotsSlide;

  static const double _total = 2200;

  Animation<T> _interval<T>(
    T begin,
    T end,
    double startMs,
    double durationMs, {
    Curve curve = Curves.easeOut,
  }) {
    return Tween<T>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(
          startMs / _total,
          math.min(1.0, (startMs + durationMs) / _total),
          curve: curve,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..forward();

    _ringCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);

    _crossCtrl = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    )..repeat();

    _shimmerCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _floatCtrl = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _dotPulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Icon entrance: bouncy pop, starts 300ms, lasts 900ms
    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.94), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 20),
    ]).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(300 / _total, 1200 / _total),
      ),
    );

    _iconOpacity = _interval(0.0, 1.0, 300, 585);

    _iconRotation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: -20.0 * math.pi / 180, end: 4.0 * math.pi / 180),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 4.0 * math.pi / 180, end: -2.0 * math.pi / 180),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -2.0 * math.pi / 180, end: 0.0),
        weight: 20,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(300 / _total, 1200 / _total),
      ),
    );

    // Glass rings: glassRingIn 0.7s starts at 200ms
    _glassRingScale = _interval(0.6, 1.0, 200, 700, curve: Curves.elasticOut);
    _glassRingOpacity = _interval(0.0, 1.0, 200, 700);

    // Pill outline draw
    _pillOpacity = _interval(0.0, 1.0, 400, 200);
    _pillDash = _interval(260.0, 0.0, 500, 1200, curve: Curves.easeInOut);

    // Text block
    _textOpacity = _interval(0.0, 1.0, 850, 700);
    _textSlide = _interval(28.0, 0.0, 850, 700);

    // Loading dots
    _dotsOpacity = _interval(0.0, 1.0, 1400, 500);
    _dotsSlide = _interval(12.0, 0.0, 1400, 500);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _crossCtrl.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    _dotPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.12, -0.2),
            radius: 1.2,
            colors: [Color(0xFF1E5E4A), Color(0xFF0D2820), Color(0xFF060F0C)],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildExpandingRings(),
            _buildGlowBlob(),
            _buildRotatingCross(),
            _buildFloatingLeaves(size),
            _buildFloatingParticles(size),
            _buildMainContent(),
            _buildLoadingDots(),
          ],
        ),
      ),
    );
  }

  // ── LAYER 1: Expanding rings ──────────────────────────────────────────────

  Widget _buildExpandingRings() {
    return AnimatedBuilder(
      animation: _ringCtrl,
      builder: (context, child) {
        return Stack(
          children: [
            for (int i = 0; i < 3; i++) _buildRing(phase: i / 3.0),
          ],
        );
      },
    );
  }

  Widget _buildRing({required double phase}) {
    final t = (_ringCtrl.value + phase) % 1.0;
    final scale = 0.8 + 2.4 * t;
    final opacity = t < 0.1
        ? (t / 0.1 * 0.6)
        : (0.6 * (1.0 - (t - 0.1) / 0.9));

    return Positioned.fill(
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF8E).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── LAYER 2: Glow blob ────────────────────────────────────────────────────

  Widget _buildGlowBlob() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final scale = 1.0 + 0.15 * _pulseCtrl.value;
        final opacity = 0.55 + 0.30 * _pulseCtrl.value;
        return Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.18),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2E7D6B).withValues(alpha: 0.35),
                        const Color(0xFF2E7D6B).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.4, 0.7],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── LAYER 3: Rotating cross ───────────────────────────────────────────────

  Widget _buildRotatingCross() {
    return AnimatedBuilder(
      animation: _crossCtrl,
      builder: (context, child) {
        return Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.18),
            child: Transform.rotate(
              angle: _crossCtrl.value * 2 * math.pi,
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _CrossPainter(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── LAYER 4: Floating leaves ──────────────────────────────────────────────

  Widget _buildFloatingLeaves(Size size) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        final t = _floatCtrl.value * math.pi;
        return Stack(
          children: [
            Positioned(
              top: size.height * 0.14,
              left: size.width * 0.11,
              child: Transform.rotate(
                angle: (-8 + 16 * math.sin(t)) * math.pi / 180,
                child: _leaf(10, 18, 0.5),
              ),
            ),
            Positioned(
              top: size.height * 0.20,
              right: size.width * 0.13,
              child: Transform.rotate(
                angle: (40 - 16 * math.sin(t + 0.8)) * math.pi / 180,
                child: _leaf(8, 14, 0.4),
              ),
            ),
            Positioned(
              top: size.height * 0.72,
              left: size.width * 0.10,
              child: Transform.rotate(
                angle: (-45 + 16 * math.sin(t + 0.4)) * math.pi / 180,
                child: _leaf(9, 16, 0.35),
              ),
            ),
            Positioned(
              top: size.height * 0.75,
              right: size.width * 0.11,
              child: Transform.rotate(
                angle: (50 - 16 * math.sin(t + 1.2)) * math.pi / 180,
                child: _leaf(7, 13, 0.45),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _leaf(double w, double h, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: w,
        height: h,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF8E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(100),
            topRight: Radius.circular(100),
            bottomRight: Radius.circular(100),
          ),
        ),
      ),
    );
  }

  // ── LAYER 5: Floating particles ───────────────────────────────────────────

  Widget _buildFloatingParticles(Size size) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        final t = _floatCtrl.value * math.pi;
        return Stack(
          children: [
            Positioned(
              top: size.height * 0.28 - 18 * math.sin(t),
              left: size.width * 0.07,
              child: Opacity(
                opacity: (0.6 + 0.4 * math.sin(t)).clamp(0.0, 1.0),
                child: _particle(5, const Color(0xFF4CAF8E)),
              ),
            ),
            Positioned(
              top: size.height * 0.32 - 14 * math.sin(t + 0.6),
              right: size.width * 0.09,
              child: Opacity(
                opacity: (0.4 + 0.4 * math.sin(t + 0.6)).clamp(0.0, 1.0),
                child: _particle(3, Colors.white.withValues(alpha: 0.45)),
              ),
            ),
            Positioned(
              top: size.height * 0.60 - 20 * math.sin(t + 0.9),
              left: size.width * 0.06,
              child: Opacity(
                opacity: (0.5 + 0.4 * math.sin(t + 0.9)).clamp(0.0, 1.0),
                child: _particle(4, const Color(0xFF4CAF8E)),
              ),
            ),
            Positioned(
              top: size.height * 0.58 - 18 * math.sin(t + 0.3),
              right: size.width * 0.07,
              child: Opacity(
                opacity: (0.3 + 0.3 * math.sin(t + 0.3)).clamp(0.0, 1.0),
                child: _particle(3, Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            Positioned(
              top: size.height * 0.45 - 20 * math.sin(t + 1.1),
              left: size.width * 0.04,
              child: Opacity(
                opacity: (0.4 + 0.4 * math.sin(t + 1.1)).clamp(0.0, 1.0),
                child: _particle(4, const Color(0xFF4CAF8E).withValues(alpha: 0.4)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _particle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ── MAIN CONTENT ──────────────────────────────────────────────────────────

  Widget _buildMainContent() {
    return Positioned.fill(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconArea(),
            const SizedBox(height: 36),
            _buildTextBlock(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconArea() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceCtrl, _pulseCtrl]),
      builder: (context, child) {
        final glowRadius = 16.0 + 6.0 * _pulseCtrl.value;
        final glowAlpha = 0.14 + 0.08 * _pulseCtrl.value;

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glass ring
              Transform.scale(
                scale: _glassRingScale.value,
                child: Opacity(
                  opacity: _glassRingOpacity.value,
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Inner glass ring
              Transform.scale(
                scale: _glassRingScale.value,
                child: Opacity(
                  opacity: _glassRingOpacity.value,
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Pill SVG drawing itself
              Opacity(
                opacity: _pillOpacity.value,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _PillPainter(dashOffset: _pillDash.value),
                  ),
                ),
              ),
              // Icon circle with entrance + glow
              Transform.rotate(
                angle: _iconRotation.value,
                child: Transform.scale(
                  scale: _iconScale.value,
                  child: Opacity(
                    opacity: _iconOpacity.value,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D6B)
                                .withValues(alpha: glowAlpha),
                            blurRadius: glowRadius,
                            spreadRadius: glowRadius / 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF2E7D6B)
                                .withValues(alpha: glowAlpha * 0.5),
                            blurRadius: glowRadius * 2,
                            spreadRadius: glowRadius,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 56,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medication_rounded,
                          size: 62,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextBlock() {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _textSlide.value),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // App name with shimmer
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (context, child) {
              final pos = _shimmerCtrl.value * 3 - 1;
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(pos - 1, 0),
                  end: Alignment(pos + 1, 0),
                  colors: const [
                    Colors.white,
                    Colors.white,
                    Color(0xFF4CAF8E),
                    Colors.white,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'İlaç Takip',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.95,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Sağlığınız, önceliğimiz.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0x8CFFFFFF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF8E).withValues(alpha: 0.18),
              border: Border.all(
                color: const Color(0xFF4CAF8E).withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF8E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sürüm 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xE64CAF8E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LOADING DOTS ──────────────────────────────────────────────────────────

  Widget _buildLoadingDots() {
    return Positioned(
      bottom: 52,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _entranceCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: _dotsOpacity.value,
            child: Transform.translate(
              offset: Offset(0, _dotsSlide.value),
              child: child,
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              _buildDot(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotPulseCtrl,
      builder: (context, child) {
        // dotPulse: at 40% → scale 1, opacity 1; at 0/80/100% → scale 0.5, opacity 0.3
        final offset = index * 0.2 / 1.5;
        final phase = ((_dotPulseCtrl.value - offset) % 1.0 + 1.0) % 1.0;
        double scale, opacity;
        if (phase < 0.4) {
          final t = phase / 0.4;
          scale = 0.5 + 0.5 * t;
          opacity = 0.3 + 0.7 * t;
        } else if (phase < 0.8) {
          final t = (phase - 0.4) / 0.4;
          scale = 1.0 - 0.5 * t;
          opacity = 1.0 - 0.7 * t;
        } else {
          scale = 0.5;
          opacity = 0.3;
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF8E),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── CUSTOM PAINTERS ───────────────────────────────────────────────────────────

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawLine(Offset(cx, 10), Offset(cx, size.height - 10), paint);
    canvas.drawLine(Offset(10, cy), Offset(size.width - 10, cy), paint);

    paint.strokeWidth = 1.5;
    canvas.drawLine(const Offset(30, 30), Offset(size.width - 30, size.height - 30), paint);
    canvas.drawLine(Offset(size.width - 30, 30), Offset(30, size.height - 30), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => false;
}

class _PillPainter extends CustomPainter {
  final double dashOffset;

  _PillPainter({required this.dashOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // SVG viewBox 80×80 scaled to size (200×200) → factor 2.5
    final scale = size.width / 80;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = const Color(0xFF4CAF8E).withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Pill outline: rect x=12 y=28 w=56 h=24 rx=12
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(12, 28, 56, 24),
          const Radius.circular(12),
        ),
      );

    for (final metric in path.computeMetrics()) {
      final drawnLength = (metric.length - dashOffset).clamp(0.0, metric.length);
      if (drawnLength > 0) {
        canvas.drawPath(metric.extractPath(0, drawnLength), paint);
      }
    }

    // Dividing line fades in after pill is mostly drawn
    if (dashOffset < 130) {
      final lineProgress = (1.0 - dashOffset / 130).clamp(0.0, 1.0);
      final linePaint = Paint()
        ..color = const Color(0xFF4CAF8E).withValues(alpha: 0.35 * lineProgress)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        const Offset(40, 28),
        Offset(40, 28 + 24 * lineProgress),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PillPainter oldDelegate) =>
      oldDelegate.dashOffset != dashOffset;
}
