import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';
import 'package:ilac_takip/ui/screens/medication_detail_screen.dart';
import 'package:ilac_takip/ui/screens/swipe_dose_screen.dart';

/// Ana ekran - Bugünkü dozlar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<MedicationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.medications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              );
            }

            if (!provider.hasMedications) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadData(),
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader(provider)),
                  
                  // İstatistikler
                  SliverToBoxAdapter(child: _buildStats(provider)),
                  
                  // Hızlı İlaç Al butonu
                  if (provider.pendingDoses.isNotEmpty)
                    SliverToBoxAdapter(child: _buildQuickActionButton(provider)),
                  
                  // Uyarılar
                  if (provider.lowStockMedications.isNotEmpty)
                    SliverToBoxAdapter(child: _buildWarnings(provider)),
                  
                  // Bugünkü dozlar başlığı
                  SliverToBoxAdapter(child: _buildSectionHeader()),
                  
                  // Doz listesi
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: _buildDoseList(provider),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.medication_liquid_outlined,
      title: 'İlaç Takibine Başlayın',
      subtitle: 'İlk ilacınızı ekleyerek düzenli ilaç takibine başlayın. Dozlarınızı asla kaçırmayın!',
      buttonText: 'İlaç Ekle',
      onButtonPressed: () => _navigateToAddMedication(),
    );
  }

  Widget _buildHeader(MedicationProvider provider) {
    final now = DateTime.now();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.isToday(now)
                          ? 'Bugün'
                          : AppDateUtils.formatDate(now),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      AppDateUtils.formatWeekday(now),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Profil avatarı
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(MedicationProvider provider) {
    final totalDoses = provider.todayScheduledDoses.length;
    final takenDoses = provider.takenDoses.length;
    final adherencePercent = (provider.todayAdherenceRate * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: 'Bugünkü Dozlar',
              value: '$takenDoses/$totalDoses',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'Uyum Oranı',
              value: '%$adherencePercent',
              icon: Icons.trending_up_rounded,
              color: adherencePercent >= 80
                  ? AppTheme.successColor
                  : adherencePercent >= 50
                      ? AppTheme.warningColor
                      : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(MedicationProvider provider) {
    final pendingCount = provider.pendingDoses.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => _navigateToSwipeDose(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swipe_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İlaç Zamanı!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingCount bekleyen doz var',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Başla',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarnings(MedicationProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.warningColor.withValues(alpha: 0.1),
              AppTheme.warningColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.warningColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Düşük Stok Uyarısı',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${provider.lowStockMedications.length} ilacın stoğu azaldı',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.warningColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          const Text(
            'Bugünkü Program',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Tümünü gör
            },
            child: const Text('Tümü'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseList(MedicationProvider provider) {
    final doses = provider.todayScheduledDoses;

    if (doses.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: const Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppTheme.successColor,
              ),
              SizedBox(height: 16),
              Text(
                'Bugün için planlanmış doz yok',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dose = doses[index];
          return DoseCard(
            scheduledDose: dose,
            onTake: () => _handleTakeDose(dose),
            onSkip: () => _handleSkipDose(dose),
            onTap: () => _navigateToMedicationDetail(dose.medication.id),
          );
        },
        childCount: doses.length,
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddMedication(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('İlaç Ekle'),
      backgroundColor: AppTheme.primaryColor,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi Geceler 🌙';
    if (hour < 12) return 'Günaydın ☀️';
    if (hour < 18) return 'İyi Günler 🌤️';
    return 'İyi Akşamlar 🌆';
  }

  void _handleTakeDose(scheduledDose) async {
    final provider = context.read<MedicationProvider>();
    final success = await provider.takeDose(scheduledDose);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${scheduledDose.medication.name} alındı olarak işaretlendi'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _handleSkipDose(scheduledDose) async {
    final provider = context.read<MedicationProvider>();
    await provider.skipDose(scheduledDose);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.skip_next, color: Colors.white),
              const SizedBox(width: 8),
              Text('${scheduledDose.medication.name} atlandı'),
            ],
          ),
          backgroundColor: AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _navigateToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  void _navigateToMedicationDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicationDetailScreen(medicationId: id)),
    );
  }

  void _navigateToSwipeDose() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SwipeDoseScreen()),
    );
  }
}
