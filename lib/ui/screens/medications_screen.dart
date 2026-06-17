import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';
import 'package:ilac_takip/ui/screens/medication_detail_screen.dart';

/// İlaçlar listesi ekranı
class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medication> _filterMedications(MedicationProvider provider) {
    final medications = provider.medications;
    if (_searchQuery.trim().isEmpty) return medications;

    final query = _searchQuery.toLowerCase();
    return medications
        .where((m) => m.name.toLowerCase().contains(query))
        .toList();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchMedicationsHint,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: context.textSecondaryClr),
                ),
                style: TextStyle(color: context.textPrimaryClr),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Text(l10n.myMedications),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _toggleSearch,
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

          final filteredMedications = _filterMedications(provider);

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            color: AppTheme.primaryColor,
            child: filteredMedications.isEmpty
                ? _buildNoResults()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredMedications.length,
                    itemBuilder: (context, index) {
                      final medication = filteredMedications[index];
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

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: context.textLightClr,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSearchResults,
              style: TextStyle(
                fontSize: 16,
                color: context.textSecondaryClr,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
