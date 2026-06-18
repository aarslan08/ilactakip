import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/ui/screens/main_navigation.dart';
import 'package:ilac_takip/ui/screens/onboarding_screen.dart';
import 'package:ilac_takip/ui/screens/quick_start_screen.dart';
import 'package:ilac_takip/ui/screens/swipe_dose_screen.dart';
import 'package:ilac_takip/ui/screens/splash_screen.dart';

/// Uygulama açılışında her zaman önce gösterilen splash + router.
///
/// Splash animasyonu oynarken veriler yüklenir, ardından:
/// - Onboarding görülmediyse: OnboardingScreen
/// - Pending doz yoksa: Ana navigasyon
/// - Tek pending doz varsa: Doğrudan SwipeDoseScreen
/// - Birden fazla pending doz varsa: QuickStartScreen
class LaunchRouter extends StatefulWidget {
  final bool showOnboarding;

  const LaunchRouter({
    super.key,
    this.showOnboarding = false,
  });

  @override
  State<LaunchRouter> createState() => _LaunchRouterState();
}

class _LaunchRouterState extends State<LaunchRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  /// Splash animasyonunun en az bu kadar süre görünmesini sağlar.
  static const Duration _minSplashDuration = Duration(milliseconds: 2200);

  Future<void> _initialize() async {
    if (!mounted) return;

    final stopwatch = Stopwatch()..start();
    final provider = context.read<MedicationProvider>();

    try {
      await provider.loadData();
      await provider.rescheduleAllNotifications();
      provider.checkMissedDoses();
    } catch (e) {
      if (mounted) {
        debugPrint('LaunchRouter initialization error: $e');
      }
    }

    // Splash animasyonu tamamlanana kadar bekle
    final remaining = _minSplashDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    // İlk açılış: önce splash, sonra onboarding.
    // Onboarding'i kendi route context'i ile açıyoruz; tamamlanınca
    // navigasyon o context üzerinden yapılır (LaunchRouter dispose olsa bile).
    if (widget.showOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (routeCtx) => OnboardingScreen(
            onComplete: () => _completeOnboarding(routeCtx),
          ),
        ),
      );
      return;
    }

    _routeToHome(context);
  }

  Future<void> _completeOnboarding(BuildContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!ctx.mounted) return;
    _routeToHome(ctx, showCoachMarks: true);
  }

  void _routeToHome(BuildContext ctx, {bool showCoachMarks = false}) {
    final provider = ctx.read<MedicationProvider>();
    final pendingDoses = provider.pendingDoses;

    Widget destination;
    if (showCoachMarks || pendingDoses.isEmpty) {
      destination = MainNavigation(showCoachMarks: showCoachMarks);
    } else if (pendingDoses.length == 1) {
      destination = SwipeDoseScreen(
        initialMedicationId: pendingDoses.first.medication.id,
      );
    } else {
      destination = QuickStartScreen(pendingDoses: pendingDoses);
    }

    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
