import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';
import 'package:ilac_takip/ui/screens/medication_detail_screen.dart';

/// İlaçlar listesi ekranı
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.myMedications),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Arama özelliği
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.medications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (!provider.hasMedications) {
            return EmptyState(
              icon: Icons.medication_outlined,
              title: l10n.noMedications,
              subtitle: l10n.addFirstMedication,
              buttonText: l10n.addMedication,
              onButtonPressed: () => _navigateToAddMedication(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.medications.length,
              itemBuilder: (context, index) {
                final medication = provider.medications[index];
                return Dismissible(
                  key: ValueKey(medication.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(context, l10n, medication.name),
                  onDismissed: (_) {
                    provider.deleteMedication(medication.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('${medication.name} ${l10n.deleted}'),
                          ],
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 4),
                        Text(
                          'Sil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: MedicationCard(
                    medication: medication,
                    onTap: () => _navigateToDetail(context, medication.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddMedication(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_rounded, color: AppTheme.errorColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${l10n.deleteMedication}?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.deleteMedicationConfirm,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.deleteMedication),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _navigateToAddMedication(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicationDetailScreen(medicationId: id)),
    );
  }
}
