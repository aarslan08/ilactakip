import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/ui/screens/main_navigation.dart';
import 'package:ilac_takip/ui/screens/quick_start_screen.dart';
import 'package:ilac_takip/ui/screens/swipe_dose_screen.dart';

/// Uygulama açılışında onboarding sonrası çalışan router.
///
/// Bugün için pending doz durumuna göre:
/// - Pending doz yoksa: Ana navigasyon
/// - Tek pending doz varsa: Doğrudan SwipeDoseScreen
/// - Birden fazla pending doz varsa: QuickStartScreen
class LaunchRouter extends StatefulWidget {
  final bool showCoachMarks;

  const LaunchRouter({
    super.key,
    this.showCoachMarks = false,
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

  Future<void> _initialize() async {
    if (!mounted) return;

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

    if (!mounted) return;

    final pendingDoses = provider.pendingDoses;

    if (pendingDoses.isEmpty) {
      _navigateTo(const MainNavigation(showCoachMarks: false));
    } else if (pendingDoses.length == 1) {
      _navigateTo(
        SwipeDoseScreen(
          initialMedicationId: pendingDoses.first.medication.id,
        ),
      );
    } else {
      _navigateTo(QuickStartScreen(pendingDoses: pendingDoses));
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
