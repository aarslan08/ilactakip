import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';
import 'package:ilac_takip/ui/screens/medication_detail_screen.dart';

/// İlaçlar listesi ekranı
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('İlaçlarım'),
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
              title: 'Henüz İlaç Yok',
              subtitle: 'İlaç ekleyerek takibe başlayın.',
              buttonText: 'İlaç Ekle',
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
                return MedicationCard(
                  medication: medication,
                  onTap: () => _navigateToDetail(context, medication.id),
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
