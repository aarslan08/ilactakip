import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/dose_log.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/ui/widgets/widgets.dart';

/// Geçmiş kayıtlar ekranı
class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Geçmiş'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Filtreleme özelliği
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          final logs = provider.recentLogs;

          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'Geçmiş Kayıt Yok',
              subtitle: 'Doz aldığınızda veya atladığınızda burada görünecek.',
            );
          }

          // Günlere göre grupla
          final groupedLogs = _groupLogsByDate(logs);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groupedLogs.length,
            itemBuilder: (context, index) {
              final entry = groupedLogs.entries.elementAt(index);
              return _buildDaySection(context, entry.key, entry.value, provider);
            },
          );
        },
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
    if (AppDateUtils.isToday(date)) return 'Bugün';
    if (AppDateUtils.isYesterday(date)) return 'Dün';
    return AppDateUtils.formatDate(date);
  }

  Widget _buildDaySection(
    BuildContext context,
    String dateTitle,
    List<DoseLog> logs,
    MedicationProvider provider,
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
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
        ...logs.map((log) => _buildLogCard(log, provider)),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLogCard(DoseLog log, MedicationProvider provider) {
    final medication = provider.getMedicationById(log.medicationId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  medication?.name ?? 'Bilinmeyen İlaç',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      log.status.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(log.status),
                      ),
                    ),
                    if (log.pillsTaken > 0) ...[
                      const Text(' • ', style: TextStyle(color: AppTheme.textLight)),
                      Text(
                        '${log.pillsTaken} adet',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (log.takenTime != null)
                Text(
                  'Alındı: ${AppDateUtils.formatTime(log.takenTime!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
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
}
