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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medication> _filterMedications(MedicationProvider provider) {
    var medications = provider.medications;

    if (_lowStockOnly) {
      medications = medications.where((m) => m.isLowStock).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      medications =
          medications.where((m) => m.name.toLowerCase().contains(query)).toList();
    }

    return medications;
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Consumer<MedicationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.medications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
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

            final filtered = _filterMedications(provider);
            final lowStockCount = provider.lowStockMedications.length;

            return Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterChips(provider.medications.length, lowStockCount),
                const SizedBox(height: 4),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadData(),
                    color: AppTheme.primaryColor,
                    child: filtered.isEmpty
                        ? _buildNoResults()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final medication = filtered[index];
                              return MedicationCard(
                                medication: medication,
                                onTap: () => _navigateToDetail(context, medication.id),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMedication(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addMedication),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        l10n.myMedications,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: context.textPrimaryClr,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.shadowAlpha),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(fontSize: 15, color: context.textPrimaryClr),
          decoration: InputDecoration(
            hintText: l10n.searchMedicationsHint,
            hintStyle: TextStyle(color: context.textLightClr, fontSize: 15),
            prefixIcon: Icon(Icons.search_rounded, color: context.textLightClr),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: context.textLightClr),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(int total, int lowStock) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: [
          _chip(
            label: '${l10n.filterAll} · $total',
            selected: !_lowStockOnly,
            onTap: () => setState(() => _lowStockOnly = false),
          ),
          const SizedBox(width: 8),
          _chip(
            label: '${l10n.filterLowStock} · $lowStock',
            selected: _lowStockOnly,
            onTap: () => setState(() => _lowStockOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : context.cardBg,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.shadowAlpha),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : context.textSecondaryClr,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: context.textLightClr),
              const SizedBox(height: 16),
              Text(
                l10n.noSearchResults,
                style: TextStyle(fontSize: 16, color: context.textSecondaryClr),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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
