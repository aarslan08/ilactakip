import 'package:flutter/foundation.dart';
import 'package:ilac_takip/data/database/database_helper.dart';
import 'package:ilac_takip/models/medication.dart';

/// İlaç repository sınıfı
class MedicationRepository {
  final DatabaseHelper _databaseHelper;

  MedicationRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Tüm ilaçları getir
  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'medications',
        orderBy: 'name ASC',
      );
      
      return maps.map((map) => Medication.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all medications: $e');
      }
      rethrow;
    }
  }

  /// İlaç getir (ID ile)
  Future<Medication?> getMedicationById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'medications',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return Medication.fromMap(maps.first);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting medication by id: $e');
      }
      rethrow;
    }
  }

  /// İlaç ekle
  Future<Medication> insertMedication(Medication medication) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('medications', medication.toMap());
      
      if (kDebugMode) {
        debugPrint('Medication inserted: ${medication.name}');
      }
      
      return medication;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inserting medication: $e');
      }
      rethrow;
    }
  }

  /// İlaç güncelle
  Future<Medication> updateMedication(Medication medication) async {
    try {
      final db = await _databaseHelper.database;
      final updatedMedication = medication.copyWith(updatedAt: DateTime.now());
      
      await db.update(
        'medications',
        updatedMedication.toMap(),
        where: 'id = ?',
        whereArgs: [medication.id],
      );
      
      if (kDebugMode) {
        debugPrint('Medication updated: ${medication.name}');
      }
      
      return updatedMedication;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating medication: $e');
      }
      rethrow;
    }
  }

  /// İlaç sil
  Future<void> deleteMedication(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'medications',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        debugPrint('Medication deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting medication: $e');
      }
      rethrow;
    }
  }

  /// Stok güncelle
  Future<Medication?> updateStock(String id, int newStock) async {
    try {
      final medication = await getMedicationById(id);
      if (medication == null) return null;
      
      final updatedMedication = medication.copyWith(
        currentStock: newStock < 0 ? 0 : newStock,
      );
      
      return await updateMedication(updatedMedication);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating stock: $e');
      }
      rethrow;
    }
  }

  /// Stok azalt
  Future<Medication?> decreaseStock(String id, int amount) async {
    try {
      final medication = await getMedicationById(id);
      if (medication == null) return null;
      
      final newStock = medication.currentStock - amount;
      return await updateStock(id, newStock);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decreasing stock: $e');
      }
      rethrow;
    }
  }

  /// Düşük stoklu ilaçları getir
  Future<List<Medication>> getLowStockMedications() async {
    try {
      final medications = await getAllMedications();
      return medications.where((m) => m.isLowStock).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting low stock medications: $e');
      }
      rethrow;
    }
  }

  /// Yakında bitecek ilaçları getir
  Future<List<Medication>> getMedicationsNearingRunout() async {
    try {
      final medications = await getAllMedications();
      return medications.where((m) => m.shouldShowRunoutWarning).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting medications nearing runout: $e');
      }
      rethrow;
    }
  }

  /// İlaç sayısını getir
  Future<int> getMedicationCount() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM medications');
      return result.first['count'] as int;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting medication count: $e');
      }
      rethrow;
    }
  }
}
