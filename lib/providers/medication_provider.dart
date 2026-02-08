import 'package:flutter/foundation.dart';
import 'package:ilac_takip/models/models.dart';
import 'package:ilac_takip/data/repositories/repositories.dart';
import 'package:ilac_takip/services/medication_service.dart';

/// İlaç state yönetimi
class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _medicationRepository;
  final DoseLogRepository _doseLogRepository;
  final MedicationService _medicationService;

  List<Medication> _medications = [];
  List<ScheduledDose> _todayScheduledDoses = [];
  List<DoseLog> _recentLogs = [];
  bool _isLoading = false;
  String? _error;

  MedicationProvider({
    MedicationRepository? medicationRepository,
    DoseLogRepository? doseLogRepository,
    MedicationService? medicationService,
  })  : _medicationRepository = medicationRepository ?? MedicationRepository(),
        _doseLogRepository = doseLogRepository ?? DoseLogRepository(),
        _medicationService = medicationService ?? MedicationService();

  // Getters
  List<Medication> get medications => _medications;
  List<ScheduledDose> get todayScheduledDoses => _todayScheduledDoses;
  List<DoseLog> get recentLogs => _recentLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMedications => _medications.isNotEmpty;

  /// Düşük stoklu ilaçlar
  List<Medication> get lowStockMedications =>
      _medications.where((m) => m.isLowStock).toList();

  /// Yakında bitecek ilaçlar
  List<Medication> get nearingRunoutMedications =>
      _medications.where((m) => m.shouldShowRunoutWarning).toList();

  /// Bekleyen dozlar
  List<ScheduledDose> get pendingDoses =>
      _todayScheduledDoses.where((d) => d.isPending).toList();

  /// Alınmış dozlar
  List<ScheduledDose> get takenDoses =>
      _todayScheduledDoses.where((d) => d.isTaken).toList();

  /// Kaçırılmış dozlar
  List<ScheduledDose> get missedDoses =>
      _todayScheduledDoses.where((d) => d.isMissed).toList();

  /// Bugünkü uyum oranı
  double get todayAdherenceRate {
    final completedDoses = _todayScheduledDoses.where((d) => !d.isPending).toList();
    if (completedDoses.isEmpty) return 1.0;
    
    final takenCount = completedDoses.where((d) => d.isTaken).length;
    return takenCount / completedDoses.length;
  }

  /// Verileri yükle
  Future<void> loadData() async {
    _setLoading(true);
    _error = null;

    try {
      _medications = await _medicationRepository.getAllMedications();
      _todayScheduledDoses = await _medicationService.getTodayScheduledDoses();
      _recentLogs = await _doseLogRepository.getDoseLogsByDate(DateTime.now());
      
      if (kDebugMode) {
        debugPrint('Loaded ${_medications.length} medications, ${_todayScheduledDoses.length} scheduled doses');
      }
    } catch (e) {
      _error = 'Veriler yüklenirken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error loading data: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// İlaç ekle
  Future<Medication?> addMedication({
    required String name,
    required int currentStock,
    required int pillsPerDose,
    required int dosesPerDay,
    List<String> scheduleTimes = const [],
    int lowStockThreshold = 5,
    int firstRunoutWarningDays = 5,
    bool perDoseReminders = true,
    String? notes,
    DateTime? expirationDate,
    IntakeType intakeType = IntakeType.either,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final medication = await _medicationService.createMedication(
        name: name,
        currentStock: currentStock,
        pillsPerDose: pillsPerDose,
        dosesPerDay: dosesPerDay,
        scheduleTimes: scheduleTimes,
        lowStockThreshold: lowStockThreshold,
        firstRunoutWarningDays: firstRunoutWarningDays,
        perDoseReminders: perDoseReminders,
        notes: notes,
        expirationDate: expirationDate,
        intakeType: intakeType,
      );

      _medications.add(medication);
      await _refreshTodaySchedule();
      notifyListeners();

      return medication;
    } catch (e) {
      _error = 'İlaç eklenirken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error adding medication: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// İlaç güncelle
  Future<Medication?> updateMedication(Medication medication) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedMedication = await _medicationService.updateMedication(medication);

      final index = _medications.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        _medications[index] = updatedMedication;
      }

      await _refreshTodaySchedule();
      notifyListeners();

      return updatedMedication;
    } catch (e) {
      _error = 'İlaç güncellenirken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error updating medication: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// İlaç sil
  Future<bool> deleteMedication(String id) async {
    _setLoading(true);
    _error = null;

    try {
      await _medicationService.deleteMedication(id);
      _medications.removeWhere((m) => m.id == id);
      await _refreshTodaySchedule();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'İlaç silinirken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error deleting medication: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dozu al
  Future<bool> takeDose(ScheduledDose scheduledDose) async {
    try {
      await _medicationService.takeDose(
        medication: scheduledDose.medication,
        scheduledTime: scheduledDose.scheduledTime,
      );

      // İlaç stoğunu güncelle
      final medicationIndex = _medications.indexWhere(
        (m) => m.id == scheduledDose.medication.id,
      );
      if (medicationIndex != -1) {
        final updatedMedication = await _medicationRepository.getMedicationById(
          scheduledDose.medication.id,
        );
        if (updatedMedication != null) {
          _medications[medicationIndex] = updatedMedication;
        }
      }

      await _refreshTodaySchedule();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Doz alınırken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error taking dose: $e');
      }
      return false;
    }
  }

  /// Dozu atla
  Future<bool> skipDose(ScheduledDose scheduledDose) async {
    try {
      await _medicationService.skipDose(
        medication: scheduledDose.medication,
        scheduledTime: scheduledDose.scheduledTime,
      );

      await _refreshTodaySchedule();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Doz atlanırken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error skipping dose: $e');
      }
      return false;
    }
  }

  /// Stok güncelle
  Future<bool> updateStock(String medicationId, int newStock) async {
    try {
      final updatedMedication = await _medicationRepository.updateStock(
        medicationId,
        newStock,
      );

      if (updatedMedication != null) {
        final index = _medications.indexWhere((m) => m.id == medicationId);
        if (index != -1) {
          _medications[index] = updatedMedication;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Stok güncellenirken hata oluştu: $e';
      if (kDebugMode) {
        debugPrint('Error updating stock: $e');
      }
      return false;
    }
  }

  /// Belirli bir ilacı getir
  Medication? getMedicationById(String id) {
    try {
      return _medications.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Belirli bir ilacın doz kayıtlarını getir
  Future<List<DoseLog>> getDoseLogsForMedication(String medicationId) async {
    try {
      return await _doseLogRepository.getDoseLogsByMedicationId(medicationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting dose logs: $e');
      }
      return [];
    }
  }

  /// Adherence oranını hesapla
  Future<double> getAdherenceRate(String medicationId) async {
    try {
      return await _doseLogRepository.calculateAdherenceRate(medicationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating adherence: $e');
      }
      return 0.0;
    }
  }

  /// Kaçırılmış dozları kontrol et
  Future<void> checkMissedDoses() async {
    try {
      await _medicationService.checkMissedDoses();
      await _refreshTodaySchedule();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking missed doses: $e');
      }
    }
  }

  /// Bugünkü programı yenile
  Future<void> _refreshTodaySchedule() async {
    _todayScheduledDoses = await _medicationService.getTodayScheduledDoses();
    _recentLogs = await _doseLogRepository.getDoseLogsByDate(DateTime.now());
  }

  /// Yükleme durumunu ayarla
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Hatayı temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
