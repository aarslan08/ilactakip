import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/screens/home_screen.dart';
import 'package:ilac_takip/ui/screens/medications_screen.dart';
import 'package:ilac_takip/ui/screens/logs_screen.dart';
import 'package:ilac_takip/ui/screens/settings_screen.dart';
import 'package:ilac_takip/ui/widgets/coach_mark_overlay.dart';

/// Ana navigasyon ekranı
class MainNavigation extends StatefulWidget {
  final bool showCoachMarks;

  const MainNavigation({super.key, this.showCoachMarks = false});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _showingCoachMarks = false;

  final GlobalKey _dosesCardKey = GlobalKey();
  final GlobalKey _statsCardKey = GlobalKey();
  final GlobalKey _quickActionKey = GlobalKey();
  final GlobalKey _scheduleKey = GlobalKey();
  final GlobalKey _navMedicationsKey = GlobalKey();
  final GlobalKey _navHistoryKey = GlobalKey();
  final GlobalKey _navSettingsKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        dosesCardKey: _dosesCardKey,
        statsCardKey: _statsCardKey,
        quickActionKey: _quickActionKey,
        scheduleKey: _scheduleKey,
      ),
      const MedicationsScreen(),
      const LogsScreen(),
      const SettingsScreen(),
    ];

    if (widget.showCoachMarks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showingCoachMarks = true);
        });
      });
    }
  }

  void startCoachMarks() {
    setState(() => _showingCoachMarks = true);
  }

  void _onCoachMarksComplete() async {
    setState(() => _showingCoachMarks = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coach_marks_shown', true);
  }

  List<CoachMarkStep> _buildCoachSteps(AppLocalizations l10n) {
    return [
      CoachMarkStep(
        targetKey: _dosesCardKey,
        title: l10n.coachDosesTitle,
        description: l10n.coachDosesDesc,
        icon: Icons.check_circle_outline_rounded,
      ),
      CoachMarkStep(
        targetKey: _statsCardKey,
        title: l10n.coachAdherenceTitle,
        description: l10n.coachAdherenceDesc,
        icon: Icons.trending_up_rounded,
      ),
      CoachMarkStep(
        targetKey: _quickActionKey,
        title: l10n.coachQuickActionTitle,
        description: l10n.coachQuickActionDesc,
        icon: Icons.swipe_rounded,
      ),
      CoachMarkStep(
        targetKey: _scheduleKey,
        title: l10n.coachScheduleTitle,
        description: l10n.coachScheduleDesc,
        icon: Icons.calendar_today_rounded,
      ),
      CoachMarkStep(
        targetKey: _navMedicationsKey,
        title: l10n.coachMedicationsTitle,
        description: l10n.coachMedicationsDesc,
        icon: Icons.medication_rounded,
      ),
      CoachMarkStep(
        targetKey: _navHistoryKey,
        title: l10n.coachHistoryTitle,
        description: l10n.coachHistoryDesc,
        icon: Icons.history_rounded,
      ),
      CoachMarkStep(
        targetKey: _navSettingsKey,
        title: l10n.coachSettingsTitle,
        description: l10n.coachSettingsDesc,
        icon: Icons.settings_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (_showingCoachMarks)
            CoachMarkOverlay(
              steps: _buildCoachSteps(l10n),
              onComplete: _onCoachMarksComplete,
              nextLabel: l10n.coachNextStep,
              finishLabel: l10n.coachGotIt,
              stepOfLabel: l10n.coachStepOf,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.shadowAlpha),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l10n.home,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.medication_outlined,
                  activeIcon: Icons.medication_rounded,
                  label: l10n.myMedications,
                  itemKey: _navMedicationsKey,
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: l10n.history,
                  itemKey: _navHistoryKey,
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: l10n.settings,
                  itemKey: _navSettingsKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    GlobalKey? itemKey,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      key: itemKey,
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : context.textSecondaryClr,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
