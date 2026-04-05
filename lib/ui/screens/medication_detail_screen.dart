import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/models/dose_log.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/screens/add_medication_screen.dart';

/// İlaç detay ekranı
class MedicationDetailScreen extends StatefulWidget {
  final String medicationId;

  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  List<DoseLog> _doseLogs = [];
  double _adherenceRate = 0.0;
  bool _isLoadingLogs = true;
  
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadDoseLogs();
  }

  Future<void> _loadDoseLogs() async {
    final provider = context.read<MedicationProvider>();
    final logs = await provider.getDoseLogsForMedication(widget.medicationId);
    final adherence = await provider.getAdherenceRate(widget.medicationId);
    
    if (mounted) {
      setState(() {
        _doseLogs = logs;
        _adherenceRate = adherence;
        _isLoadingLogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        final medication = provider.getMedicationById(widget.medicationId);

        if (medication == null) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            appBar: AppBar(title: Text(l10n.medicationDetails)),
            body: Center(child: Text(l10n.unknownMedication)),
          );
        }

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          body: CustomScrollView(
            slivers: [
              // App Bar
              _buildSliverAppBar(medication),
              
              // İçerik
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stok kartı
                      _buildStockCard(medication),
                      const SizedBox(height: 20),
                      
                      // Dozaj bilgileri
                      _buildDosageInfo(medication),
                      const SizedBox(height: 20),
                      
                      // Uyum oranı
                      _buildAdherenceSection(),
                      const SizedBox(height: 20),
                      
                      // Son dozlar
                      _buildRecentDoses(),
                      const SizedBox(height: 20),
                      
                      // Aksiyonlar
                      _buildActions(medication, provider),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(Medication medication) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () => _navigateToEdit(medication),
        ),
      ],
    );
  }

  Widget _buildStockCard(Medication medication) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStockItem(
                  l10n.currentStock,
                  '${medication.currentStock}',
                  l10n.units,
                  Icons.inventory_2_rounded,
                  medication.isLowStock ? AppTheme.warningColor : AppTheme.primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: context.dividerClr,
              ),
              Expanded(
                child: _buildStockItem(
                  l10n.estimatedDays,
                  medication.estimatedDaysLeft >= 999
                      ? '∞'
                      : '${medication.estimatedDaysLeft}',
                  l10n.daysSupply,
                  Icons.calendar_today_rounded,
                  medication.shouldShowRunoutWarning
                      ? AppTheme.accentColor
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stok güncelleme
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStockDialog(medication, false),
                  icon: const Icon(Icons.remove_rounded),
                  label: Text(l10n.delete),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStockDialog(medication, true),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondaryClr,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondaryClr,
          ),
        ),
      ],
    );
  }

  Widget _buildDosageInfo(Medication medication) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dosageInfo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryClr,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.medication_outlined,
            l10n.pillsPerDose,
            '${medication.dosage.pillsPerDose} ${l10n.units}',
          ),
          Divider(height: 24, color: context.dividerClr),
          _buildInfoRow(
            Icons.repeat_rounded,
            l10n.dosesPerDay,
            '${medication.dosage.dosesPerDay} ${l10n.times}',
          ),
          if (medication.dosage.scheduleTimes.isNotEmpty) ...[
            Divider(height: 24, color: context.dividerClr),
            _buildInfoRow(
              Icons.schedule_rounded,
              l10n.doseTimes,
              medication.dosage.scheduleTimes.join(' • '),
            ),
          ],
          if (medication.expirationDate != null) ...[
            Divider(height: 24, color: context.dividerClr),
            _buildInfoRow(
              Icons.event_rounded,
              l10n.expirationDate,
              AppDateUtils.formatDate(medication.expirationDate!),
            ),
          ],
          if (medication.notes != null && medication.notes!.isNotEmpty) ...[
            Divider(height: 24, color: context.dividerClr),
            _buildInfoRow(
              Icons.note_rounded,
              l10n.notes,
              medication.notes!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondaryClr,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryClr,
          ),
        ),
      ],
    );
  }

  Widget _buildAdherenceSection() {
    final percentage = (_adherenceRate * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.adherenceRate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryClr,
                ),
              ),
              const Spacer(),
              Text(
                '%$percentage',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getAdherenceColor(percentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _adherenceRate,
              minHeight: 10,
              backgroundColor: context.dividerClr,
              valueColor: AlwaysStoppedAnimation(_getAdherenceColor(percentage)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getAdherenceMessage(percentage),
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryClr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDoses() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.shadowAlpha),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.doseHistory,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryClr,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Tüm geçmişi gör
                },
                child: Text(l10n.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLogs)
            const Center(child: CircularProgressIndicator())
          else if (_doseLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noHistory,
                style: TextStyle(color: context.textSecondaryClr),
              ),
            )
          else
            ...(_doseLogs.take(5).map((log) => _buildLogItem(log))),
        ],
      ),
    );
  }

  Widget _buildLogItem(DoseLog log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getStatusColor(log.status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(log.status),
              size: 18,
              color: _getStatusColor(log.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(log.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryClr,
                  ),
                ),
                Text(
                  AppDateUtils.timeAgo(log.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryClr,
                  ),
                ),
              ],
            ),
          ),
          Text(
            log.scheduledTime != null
                ? AppDateUtils.formatTime(log.scheduledTime!)
                : '',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryClr,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return l10n.takenStatus;
      case DoseStatus.missed:
        return l10n.missedStatus;
      case DoseStatus.skipped:
        return l10n.skippedStatus;
    }
  }

  Widget _buildActions(Medication medication, MedicationProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToEdit(medication),
            icon: const Icon(Icons.edit_rounded),
            label: Text(l10n.editMedication),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _showDeleteDialog(medication, provider),
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
            label: Text(
              l10n.deleteMedication,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ),
      ],
    );
  }

  Color _getAdherenceColor(int percentage) {
    if (percentage >= 80) return AppTheme.successColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getAdherenceMessage(int percentage) {
    if (percentage >= 90) return 'Mükemmel! Dozlarınızı düzenli alıyorsunuz. 🎉';
    if (percentage >= 80) return 'Çok iyi! Biraz daha dikkat ile %100\'e ulaşabilirsiniz.';
    if (percentage >= 50) return 'İyileştirme gerekli. Hatırlatıcıları açmayı deneyin.';
    return 'Dozlarınızı kaçırıyorsunuz. Düzenli almak önemli!';
  }

  Color _getStatusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return AppTheme.takenColor;
      case DoseStatus.missed:
        return AppTheme.missedColor;
      case DoseStatus.skipped:
        return AppTheme.skippedColor;
    }
  }

  IconData _getStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Icons.check_circle_rounded;
      case DoseStatus.missed:
        return Icons.cancel_rounded;
      case DoseStatus.skipped:
        return Icons.skip_next_rounded;
    }
  }

  void _showStockDialog(Medication medication, bool isAdd) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAdd ? l10n.add : l10n.delete),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.stockHint,
            hintText: l10n.stockHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                final newStock = isAdd
                    ? medication.currentStock + amount
                    : medication.currentStock - amount;
                
                await context.read<MedicationProvider>().updateStock(
                  medication.id,
                  newStock,
                );
                
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Medication medication, MedicationProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteMedication),
        content: Text(l10n.deleteMedicationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await provider.deleteMedication(medication.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext); // Dialog
              }
              if (mounted) {
                navigator.pop(); // Detail screen
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(medication: medication),
      ),
    );
  }
}
