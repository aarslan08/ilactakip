import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:ilac_takip/models/models.dart';
import 'package:ilac_takip/data/repositories/repositories.dart';
import 'package:ilac_takip/services/notification_service.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/core/constants/app_constants.dart';

/// İlaç işlemleri servisi
class MedicationService {
  final MedicationRepository _medicationRepository;
  final DoseLogRepository _doseLogRepository;
  final NotificationService _notificationService;
  final Uuid _uuid;

  MedicationService({
    MedicationRepository? medicationRepository,
    DoseLogRepository? doseLogRepository,
    NotificationService? notificationService,
  })  : _medicationRepository = medicationRepository ?? MedicationRepository(),
        _doseLogRepository = doseLogRepository ?? DoseLogRepository(),
        _notificationService = notificationService ?? NotificationService.instance,
        _uuid = const Uuid();

  /// Yeni ilaç oluştur
  Future<Medication> createMedication({
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
    final now = DateTime.now();
    
    final medication = Medication(
      id: _uuid.v4(),
      name: name,
      currentStock: currentStock,
      startDate: now,
      dosage: Dosage(
        pillsPerDose: pillsPerDose,
        dosesPerDay: dosesPerDay,
        scheduleTimes: scheduleTimes,
      ),
      lowStockThreshold: lowStockThreshold,
      firstRunoutWarningDays: firstRunoutWarningDays,
      perDoseReminders: perDoseReminders,
      notes: notes,
      expirationDate: expirationDate,
      intakeType: intakeType,
      createdAt: now,
      updatedAt: now,
    );

    final savedMedication = await _medicationRepository.insertMedication(medication);
    
    // Doz hatırlatıcılarını programla
    await _scheduleDoseReminders(savedMedication);
    
    // Stok kontrolü
    await _checkAndNotifyStock(savedMedication);

    return savedMedication;
  }

  /// İlaç güncelle
  Future<Medication> updateMedication(Medication medication) async {
    final updatedMedication = await _medicationRepository.updateMedication(medication);
    
    // Bildirimleri yeniden programla
    await _notificationService.cancelMedicationNotifications(medication.id);
    await _scheduleDoseReminders(updatedMedication);
    await _checkAndNotifyStock(updatedMedication);

    return updatedMedication;
  }

  /// İlaç sil
  Future<void> deleteMedication(String id) async {
    await _notificationService.cancelMedicationNotifications(id);
    await _doseLogRepository.deleteDoseLogsByMedicationId(id);
    await _medicationRepository.deleteMedication(id);
  }

  /// Dozu alındı olarak işaretle
  Future<DoseLog> takeDose({
    required Medication medication,
    required String scheduledTime,
    String? notes,
  }) async {
    final now = DateTime.now();
    
    // Programlanmış zamanı oluştur
    final timeParts = scheduledTime.split(':');
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    // Doz kaydı oluştur
    final doseLog = DoseLog(
      id: _uuid.v4(),
      medicationId: medication.id,
      scheduledTime: scheduledDateTime,
      takenTime: now,
      status: DoseStatus.taken,
      pillsTaken: medication.dosage.pillsPerDose,
      notes: notes,
      createdAt: now,
    );

    await _doseLogRepository.insertDoseLog(doseLog);

    // Stoğu azalt
    final newStock = medication.currentStock - medication.dosage.pillsPerDose;
    final updatedMedication = await _medicationRepository.updateStock(
      medication.id,
      newStock,
    );

    // Stok kontrolü
    if (updatedMedication != null) {
      await _checkAndNotifyStock(updatedMedication);
    }

    if (kDebugMode) {
      debugPrint('Dose taken for ${medication.name}, new stock: $newStock');
    }

    return doseLog;
  }

  /// Dozu atla
  Future<DoseLog> skipDose({
    required Medication medication,
    required String scheduledTime,
    String? notes,
  }) async {
    final now = DateTime.now();
    
    final timeParts = scheduledTime.split(':');
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final doseLog = DoseLog(
      id: _uuid.v4(),
      medicationId: medication.id,
      scheduledTime: scheduledDateTime,
      status: DoseStatus.skipped,
      pillsTaken: 0,
      notes: notes,
      createdAt: now,
    );

    await _doseLogRepository.insertDoseLog(doseLog);

    if (kDebugMode) {
      debugPrint('Dose skipped for ${medication.name}');
    }

    return doseLog;
  }

  /// Dozu kaçırıldı olarak işaretle
  Future<DoseLog> markDoseAsMissed({
    required Medication medication,
    required String scheduledTime,
  }) async {
    final now = DateTime.now();
    
    final timeParts = scheduledTime.split(':');
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final doseLog = DoseLog(
      id: _uuid.v4(),
      medicationId: medication.id,
      scheduledTime: scheduledDateTime,
      status: DoseStatus.missed,
      pillsTaken: 0,
      createdAt: now,
    );

    await _doseLogRepository.insertDoseLog(doseLog);

    // Bildirim gönder
    await _notificationService.showMissedDoseNotification(
      medication: medication,
      scheduledTime: scheduledTime,
    );

    if (kDebugMode) {
      debugPrint('Dose marked as missed for ${medication.name}');
    }

    return doseLog;
  }

  /// Bugünkü programlanmış dozları getir
  Future<List<ScheduledDose>> getTodayScheduledDoses() async {
    final medications = await _medicationRepository.getAllMedications();
    final today = DateTime.now();
    final scheduledDoses = <ScheduledDose>[];

    for (final medication in medications) {
      if (medication.dosage.scheduleTimes.isEmpty) {
        // Saat belirtilmemişse varsayılan saatler kullan
        final defaultTimes = _generateDefaultTimes(medication.dosage.dosesPerDay);
        for (final time in defaultTimes) {
          final scheduledDose = await _createScheduledDose(medication, time, today);
          scheduledDoses.add(scheduledDose);
        }
      } else {
        for (final time in medication.dosage.scheduleTimes) {
          final scheduledDose = await _createScheduledDose(medication, time, today);
          scheduledDoses.add(scheduledDose);
        }
      }
    }

    // Saate göre sırala
    scheduledDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return scheduledDoses;
  }

  /// ScheduledDose oluştur
  Future<ScheduledDose> _createScheduledDose(
    Medication medication,
    String scheduledTime,
    DateTime date,
  ) async {
    final timeParts = scheduledTime.split(':');
    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    // Bu doz için kayıt var mı kontrol et
    final existingLog = await _doseLogRepository.findDoseLogByScheduledTime(
      medication.id,
      scheduledDateTime,
    );

    return ScheduledDose(
      medication: medication,
      scheduledTime: scheduledTime,
      scheduledDateTime: scheduledDateTime,
      doseLog: existingLog,
    );
  }

  /// Varsayılan saatler oluştur
  List<String> _generateDefaultTimes(int dosesPerDay) {
    switch (dosesPerDay) {
      case 1:
        return ['09:00'];
      case 2:
        return ['09:00', '21:00'];
      case 3:
        return ['08:00', '14:00', '20:00'];
      case 4:
        return ['08:00', '12:00', '16:00', '20:00'];
      default:
        final times = <String>[];
        final interval = 24 ~/ dosesPerDay;
        for (int i = 0; i < dosesPerDay; i++) {
          final hour = (8 + (i * interval)) % 24;
          times.add('${hour.toString().padLeft(2, '0')}:00');
        }
        return times;
    }
  }

  /// Doz hatırlatıcılarını programla
  Future<void> _scheduleDoseReminders(Medication medication) async {
    if (!medication.perDoseReminders) return;
    if (medication.dosage.scheduleTimes.isEmpty) return;

    final now = DateTime.now();
    int notificationId = AppConstants.doseReminderNotificationId + medication.id.hashCode;

    for (final time in medication.dosage.scheduleTimes) {
      final parsedTime = AppDateUtils.parseTime(time);
      if (parsedTime == null) continue;

      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // Eğer zaman geçmişse yarına programla
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await _notificationService.scheduleDoseReminder(
        medication: medication,
        scheduledTime: scheduledDateTime,
        notificationId: notificationId++,
      );
    }
  }

  /// Stok kontrolü ve bildirim
  Future<void> _checkAndNotifyStock(Medication medication) async {
    final now = DateTime.now();
    final lastNotified = medication.lastNotified;

    // 5 gün kala uyarısı
    if (medication.estimatedDaysLeft == medication.firstRunoutWarningDays) {
      final lastRunoutNotified = lastNotified.runout5daysAt;
      if (lastRunoutNotified == null ||
          AppDateUtils.daysBetween(lastRunoutNotified, now) >= 1) {
        await _notificationService.showRunoutWarningNotification(
          medication: medication,
        );
        
        // lastNotified güncelle
        final updatedMedication = medication.copyWith(
          lastNotified: lastNotified.copyWith(runout5daysAt: now),
        );
        await _medicationRepository.updateMedication(updatedMedication);
      }
    }

    // Düşük stok uyarısı
    if (medication.isLowStock) {
      final lastLowStockNotified = lastNotified.lowStockAt;
      if (lastLowStockNotified == null ||
          AppDateUtils.daysBetween(lastLowStockNotified, now) >= 1) {
        await _notificationService.showLowStockNotification(
          medication: medication,
        );
        
        // lastNotified güncelle
        final updatedMedication = medication.copyWith(
          lastNotified: lastNotified.copyWith(lowStockAt: now),
        );
        await _medicationRepository.updateMedication(updatedMedication);
      }
    }
  }

  /// Kaçırılmış dozları kontrol et
  Future<void> checkMissedDoses() async {
    final scheduledDoses = await getTodayScheduledDoses();
    final now = DateTime.now();
    const gracePeriod = Duration(minutes: 60);

    for (final dose in scheduledDoses) {
      if (dose.isPending) {
        final deadlineTime = dose.scheduledDateTime.add(gracePeriod);
        if (now.isAfter(deadlineTime)) {
          await markDoseAsMissed(
            medication: dose.medication,
            scheduledTime: dose.scheduledTime,
          );
        }
      }
    }
  }

  /// Tüm stokları kontrol et
  Future<void> checkAllStocks() async {
    final medications = await _medicationRepository.getAllMedications();
    for (final medication in medications) {
      await _checkAndNotifyStock(medication);
    }
  }
}
