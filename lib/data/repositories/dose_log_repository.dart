import 'package:flutter/foundation.dart';
import 'package:ilac_takip/data/database/database_helper.dart';
import 'package:ilac_takip/models/dose_log.dart';

/// Doz kaydı repository sınıfı
class DoseLogRepository {
  final DatabaseHelper _databaseHelper;

  DoseLogRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Tüm doz kayıtlarını getir
  Future<List<DoseLog>> getAllDoseLogs() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'dose_logs',
        orderBy: 'createdAt DESC',
      );
      
      return maps.map((map) => DoseLog.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all dose logs: $e');
      }
      rethrow;
    }
  }

  /// Belirli bir ilacın doz kayıtlarını getir
  Future<List<DoseLog>> getDoseLogsByMedicationId(String medicationId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'dose_logs',
        where: 'medicationId = ?',
        whereArgs: [medicationId],
        orderBy: 'createdAt DESC',
      );
      
      return maps.map((map) => DoseLog.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting dose logs by medication: $e');
      }
      rethrow;
    }
  }

  /// Belirli bir tarihteki doz kayıtlarını getir
  Future<List<DoseLog>> getDoseLogsByDate(DateTime date) async {
    try {
      final db = await _databaseHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final maps = await db.query(
        'dose_logs',
        where: 'createdAt >= ? AND createdAt <= ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'scheduledTime ASC',
      );
      
      return maps.map((map) => DoseLog.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting dose logs by date: $e');
      }
      rethrow;
    }
  }

  /// Belirli bir ilaç ve tarih için doz kaydı getir
  Future<List<DoseLog>> getDoseLogsByMedicationAndDate(
    String medicationId,
    DateTime date,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final maps = await db.query(
        'dose_logs',
        where: 'medicationId = ? AND createdAt >= ? AND createdAt <= ?',
        whereArgs: [
          medicationId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        orderBy: 'scheduledTime ASC',
      );
      
      return maps.map((map) => DoseLog.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting dose logs by medication and date: $e');
      }
      rethrow;
    }
  }

  /// Belirli bir programlanmış zaman için doz kaydı bul
  Future<DoseLog?> findDoseLogByScheduledTime(
    String medicationId,
    DateTime scheduledTime,
  ) async {
    try {
      final db = await _databaseHelper.database;
      
      // Aynı gün içinde ve aynı saat için kayıt ara
      final startOfDay = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
      );
      final endOfDay = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        23,
        59,
        59,
      );
      
      final timeString = '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
      
      final maps = await db.query(
        'dose_logs',
        where: 'medicationId = ? AND scheduledTime LIKE ? AND createdAt >= ? AND createdAt <= ?',
        whereArgs: [
          medicationId,
          '%T$timeString%',
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return DoseLog.fromMap(maps.first);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error finding dose log by scheduled time: $e');
      }
      rethrow;
    }
  }

  /// Doz kaydı ekle
  Future<DoseLog> insertDoseLog(DoseLog doseLog) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('dose_logs', doseLog.toMap());
      
      if (kDebugMode) {
        debugPrint('Dose log inserted: ${doseLog.id}');
      }
      
      return doseLog;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inserting dose log: $e');
      }
      rethrow;
    }
  }

  /// Doz kaydı güncelle
  Future<DoseLog> updateDoseLog(DoseLog doseLog) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'dose_logs',
        doseLog.toMap(),
        where: 'id = ?',
        whereArgs: [doseLog.id],
      );
      
      if (kDebugMode) {
        debugPrint('Dose log updated: ${doseLog.id}');
      }
      
      return doseLog;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating dose log: $e');
      }
      rethrow;
    }
  }

  /// Doz kaydı sil
  Future<void> deleteDoseLog(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'dose_logs',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        debugPrint('Dose log deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting dose log: $e');
      }
      rethrow;
    }
  }

  /// Belirli bir ilacın tüm doz kayıtlarını sil
  Future<void> deleteDoseLogsByMedicationId(String medicationId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'dose_logs',
        where: 'medicationId = ?',
        whereArgs: [medicationId],
      );
      
      if (kDebugMode) {
        debugPrint('All dose logs deleted for medication: $medicationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting dose logs by medication: $e');
      }
      rethrow;
    }
  }

  /// Adherence (uyum) oranını hesapla
  Future<double> calculateAdherenceRate(
    String medicationId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final logs = await getDoseLogsByMedicationId(medicationId);
      
      if (logs.isEmpty) return 0.0;
      
      final filteredLogs = logs.where((log) {
        if (startDate != null && log.createdAt.isBefore(startDate)) return false;
        if (endDate != null && log.createdAt.isAfter(endDate)) return false;
        return true;
      }).toList();
      
      if (filteredLogs.isEmpty) return 0.0;
      
      final takenCount = filteredLogs.where((log) => log.isTaken).length;
      return takenCount / filteredLogs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating adherence rate: $e');
      }
      rethrow;
    }
  }

  /// Bugünkü alınmış doz sayısını getir
  Future<int> getTodayTakenCount(String medicationId) async {
    try {
      final today = DateTime.now();
      final logs = await getDoseLogsByMedicationAndDate(medicationId, today);
      return logs.where((log) => log.isTaken).length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting today taken count: $e');
      }
      rethrow;
    }
  }

  /// Toplam doz kaydı sayısını getir
  Future<int> getDoseLogCount() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM dose_logs');
      return result.first['count'] as int;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting dose log count: $e');
      }
      rethrow;
    }
  }
}
