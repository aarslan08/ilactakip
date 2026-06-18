import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _ambientCtrl;

  // Tasarım renkleri
  static const Color _bgDeep = Color(0xFF060F0B);
  static const Color _accent = Color(0xFF4CAF8E);
  static const Color _textPrimary = Colors.white;
  static const Color _textMuted = Color(0xA6DFF2EC);

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  List<_OnboardingPageData> get _pages => [
        _OnboardingPageData(
          icon: Icons.medication_rounded,
          kicker: l10n.onboardingKicker1,
          title: l10n.onboardingTitle1,
          description: l10n.onboardingDesc1,
          color: AppTheme.primaryColor,
        ),
        _OnboardingPageData(
          icon: Icons.notifications_active_rounded,
          kicker: l10n.onboardingKicker2,
          title: l10n.onboardingTitle2,
          description: l10n.onboardingDesc2,
          color: AppTheme.accentColor,
        ),
        _OnboardingPageData(
          icon: Icons.insights_rounded,
          kicker: l10n.onboardingKicker3,
          title: l10n.onboardingTitle3,
          description: l10n.onboardingDesc3,
          color: const Color(0xFF5A9BE8),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _bgDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.04, -0.45),
            radius: 1.1,
            colors: [Color(0xFF1A5040), Color(0xFF0B1E16), _bgDeep],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip butonu
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: isLastPage
                      ? const SizedBox(height: 48)
                      : TextButton(
                          onPressed: widget.onComplete,
                          child: Text(
                            l10n.onboardingSkip,
                            style: TextStyle(
                              fontSize: 15,
                              color: _accent.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),

              // Sayfalar
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => _buildPage(_pages[index]),
                ),
              ),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _accent
                          : _accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Alt buton - gradyan
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryColor, _accent],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.45),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLastPage) ...[
                          const Icon(Icons.rocket_launch_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          isLastPage
                              ? l10n.onboardingGetStarted
                              : l10n.onboardingContinue,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLastPage) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 22),
                        ],
                      ],
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

  Widget _buildPage(_OnboardingPageData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHero(data),
          const SizedBox(height: 44),
          Text(
            data.kicker.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _accent,
              letterSpacing: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: _textMuted,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHero(_OnboardingPageData data) {
    return AnimatedBuilder(
      animation: _ambientCtrl,
      builder: (context, child) {
        final t = _ambientCtrl.value;
        // Yüzen hareket (floatUp)
        final floatY = -10 * math.sin(t * 2 * math.pi);
        // Orb nabzı (orbPulse)
        final orbScale = 1.0 + 0.1 * math.sin(t * 2 * math.pi);
        final orbOpacity = 0.6 + 0.25 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Genişleyen halkalar (ringOut)
              _expandingRing(phase: 0.0),
              _expandingRing(phase: 0.5),
              // Nabız atan orb
              Transform.scale(
                scale: orbScale,
                child: Opacity(
                  opacity: orbOpacity.clamp(0.0, 1.0),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.18),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Yüzen gradyan ikon dairesi
              Transform.translate(
                offset: Offset(0, floatY),
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, _accent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: 56, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _expandingRing({required double phase}) {
    final t = (_ambientCtrl.value + phase) % 1.0;
    final scale = 0.7 + 1.5 * t;
    final opacity = 0.7 * (1.0 - t);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String kicker;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.description,
    required this.color,
  });
}
