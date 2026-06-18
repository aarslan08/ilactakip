import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/models/dose_log.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';

/// Geçmiş kayıtlar ekranı
class LogsScreen extends StatefulWidget {
  final String? medicationId;
  /// Takvimden açılınca bu güne otomatik filtre uygulanır.
  final DateTime? initialDate;

  const LogsScreen({
    super.key,
    this.medicationId,
    this.initialDate,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<DoseLog> _allLogs = [];
  List<DoseLog> _filteredLogs = [];
  bool _isLoading = true;
  Medication? _medication;

  // Filtreler
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMedicationId;
  DoseStatus? _selectedStatus;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _selectedMedicationId = widget.medicationId;
    if (widget.initialDate != null) {
      final d = widget.initialDate!;
      _startDate = DateTime(d.year, d.month, d.day);
      _endDate = DateTime(d.year, d.month, d.day);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    final provider = context.read<MedicationProvider>();

    if (widget.medicationId != null) {
      _medication = provider.getMedicationById(widget.medicationId!);
      _allLogs = await provider.getDoseLogsForMedication(widget.medicationId!);
    } else {
      await provider.loadData();
      _allLogs = provider.recentLogs;
    }

    _applyFilters();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLogs() async {
    final provider = context.read<MedicationProvider>();
    await provider.loadData();
    await _loadLogs();
  }

  void _applyFilters() {
    _filteredLogs = _allLogs.where((log) {
      // Tarih aralığı filtresi
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final logDay = DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
        if (logDay.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (log.createdAt.isAfter(end)) return false;
      }

      // İlaç filtresi
      if (_selectedMedicationId != null &&
          _selectedMedicationId != 'all' &&
          log.medicationId != _selectedMedicationId) {
        return false;
      }

      // Durum filtresi
      if (_selectedStatus != null && log.status != _selectedStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters {
    return _startDate != null ||
        _endDate != null ||
        (_selectedMedicationId != null && _selectedMedicationId != 'all') ||
        _selectedStatus != null;
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedMedicationId = widget.medicationId;
      _selectedStatus = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _groupLogsByDate(_filteredLogs);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _medication != null
              ? '${_medication!.name} ${l10n.history}'
              : l10n.history,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _filteredLogs.isEmpty
              ? EmptyState(
                  icon: Icons.history_rounded,
                  title: l10n.noHistory,
                  subtitle: l10n.historyWillAppear,
                )
              : RefreshIndicator(
                  onRefresh: _refreshLogs,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: groupedLogs.length + (_hasActiveFilters ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_hasActiveFilters && index == 0) {
                        return _buildActiveFilters();
                      }
                      final entry = groupedLogs.entries
                          .elementAt(_hasActiveFilters ? index - 1 : index);
                      return _buildDaySection(context, entry.key, entry.value);
                    },
                  ),
                ),
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.activeFilters,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: _resetFilters,
            child: Text(l10n.resetFilters),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final provider = context.read<MedicationProvider>();
    final medications = provider.medications;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.dividerClr,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.filterTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryClr,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarih aralığı
                  _buildDateRangeFilter(setModalState),
                  const SizedBox(height: 20),

                  // İlaç seçimi (sadece tüm geçmiş modunda)
                  if (widget.medicationId == null)
                    _buildMedicationFilter(medications, setModalState),
                  if (widget.medicationId == null)
                    const SizedBox(height: 20),

                  // Durum seçimi
                  _buildStatusFilter(setModalState),
                  const SizedBox(height: 32),

                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          child: Text(l10n.resetFilters),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _applyFilters());
                            Navigator.pop(context);
                          },
                          child: Text(l10n.apply),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateRangeFilter(void Function(void Function()) setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.startDate} - ${l10n.endDate}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryClr,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: now.subtract(const Duration(days: 365 * 5)),
              lastDate: now,
              initialDateRange: _startDate != null && _endDate != null
                  ? DateTimeRange(start: _startDate!, end: _endDate!)
                  : null,
            );
            if (picked != null) {
              setModalState(() {
                _startDate = picked.start;
                _endDate = picked.end;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.subtleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.dividerClr),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _startDate != null && _endDate != null
                        ? '${AppDateUtils.formatDate(_startDate!)} - ${AppDateUtils.formatDate(_endDate!)}'
                        : '${l10n.startDate} - ${l10n.endDate}',
                    style: TextStyle(
                      fontSize: 15,
                      color: _startDate != null && _endDate != null
                          ? context.textPrimaryClr
                          : context.textSecondaryClr,
                    ),
                  ),
                ),
                if (_startDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => setModalState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    color: context.textSecondaryClr,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationFilter(
    List<Medication> medications,
    void Function(void Function()) setModalState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectMedication,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryClr,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.subtleBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerClr),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedMedicationId ?? 'all',
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(l10n.allMedications),
                ),
                ...medications.map((med) => DropdownMenuItem(
                      value: med.id,
                      child: Text(med.name),
                    )),
              ],
              onChanged: (value) {
                setModalState(() {
                  _selectedMedicationId = value == 'all' ? null : value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(void Function(void Function()) setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.status,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryClr,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip(
              label: l10n.allStatuses,
              isSelected: _selectedStatus == null,
              color: AppTheme.primaryColor,
              onTap: () => setModalState(() => _selectedStatus = null),
            ),
            _buildStatusChip(
              label: l10n.takenStatus,
              isSelected: _selectedStatus == DoseStatus.taken,
              color: AppTheme.takenColor,
              onTap: () => setModalState(() => _selectedStatus = DoseStatus.taken),
            ),
            _buildStatusChip(
              label: l10n.missedStatus,
              isSelected: _selectedStatus == DoseStatus.missed,
              color: AppTheme.missedColor,
              onTap: () => setModalState(() => _selectedStatus = DoseStatus.missed),
            ),
            _buildStatusChip(
              label: l10n.skippedStatus,
              isSelected: _selectedStatus == DoseStatus.skipped,
              color: AppTheme.skippedColor,
              onTap: () => setModalState(() => _selectedStatus = DoseStatus.skipped),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : context.subtleBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : context.dividerClr,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : context.textSecondaryClr,
          ),
        ),
      ),
    );
  }

  Map<String, List<DoseLog>> _groupLogsByDate(List<DoseLog> logs) {
    final grouped = <String, List<DoseLog>>{};

    for (final log in logs) {
      final dateKey = _getDateKey(log.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    if (AppDateUtils.isToday(date)) return l10n.todayLabel;
    if (AppDateUtils.isYesterday(date)) return l10n.yesterdayLabel;
    return AppDateUtils.formatDate(date);
  }

  Widget _buildDaySection(
    BuildContext context,
    String dateTitle,
    List<DoseLog> logs,
  ) {
    // İstatistikler
    final takenCount = logs.where((l) => l.isTaken).length;
    final missedCount = logs.where((l) => l.isMissed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarih başlığı
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Text(
                dateTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryClr,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$takenCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (missedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cancel,
                        size: 14,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$missedCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Log kartları
        ...logs.map((log) => _buildLogCard(context, log)),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    DoseLog log,
  ) {
    final provider = context.read<MedicationProvider>();
    final medication = provider.getMedicationById(log.medicationId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(log.status).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Durum ikonu
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getStatusColor(log.status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(log.status),
              color: _getStatusColor(log.status),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // İlaç bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication?.name ?? l10n.unknownMedication,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryClr,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _getStatusLabel(log.status),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(log.status),
                      ),
                    ),
                    if (log.pillsTaken > 0) ...[
                      Text(
                        ' • ',
                        style: TextStyle(color: context.textLightClr),
                      ),
                      Text(
                        '${log.pillsTaken} ${l10n.pills}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryClr,
                        ),
                      ),
                    ],
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 14,
                          color: context.textLightClr),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          log.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textLightClr,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Zaman
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (log.scheduledTime != null)
                Text(
                  AppDateUtils.formatTime(log.scheduledTime!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryClr,
                  ),
                ),
              if (log.takenTime != null)
                Text(
                  '${l10n.takenAt}: ${AppDateUtils.formatTime(log.takenTime!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryClr,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
}
