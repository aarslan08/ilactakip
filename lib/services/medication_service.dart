import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:ilac_takip/models/models.dart';
import 'package:ilac_takip/data/repositories/repositories.dart';
import 'package:ilac_takip/services/notification_service.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';

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
    FrequencyType frequencyType = FrequencyType.daily,
    List<int> weeklyDays = const [],
    int? monthlyDay,
    int lowStockThreshold = 5,
    int firstRunoutWarningDays = 5,
    bool perDoseReminders = true,
    String? notes,
    DateTime? expirationDate,
    IntakeType intakeType = IntakeType.either,
    int colorValue = 0xFF2E7D6B,
    int iconIndex = 0,
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
        frequencyType: frequencyType,
        weeklyDays: weeklyDays,
        monthlyDay: monthlyDay,
      ),
      lowStockThreshold: lowStockThreshold,
      firstRunoutWarningDays: firstRunoutWarningDays,
      perDoseReminders: perDoseReminders,
      notes: notes,
      expirationDate: expirationDate,
      intakeType: intakeType,
      colorValue: colorValue,
      iconIndex: iconIndex,
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

    // Bu doz için zaten bir kayıt varsa (kaçırıldı/atlandı) onu güncelle,
    // yoksa yeni kayıt oluştur. Aksi halde aynı doz için birden çok kayıt oluşur.
    final existingLog = await _doseLogRepository.findDoseLogByScheduledTime(
      medication.id,
      scheduledDateTime,
    );

    final doseLog = DoseLog(
      id: existingLog?.id ?? _uuid.v4(),
      medicationId: medication.id,
      scheduledTime: scheduledDateTime,
      takenTime: now,
      status: DoseStatus.taken,
      pillsTaken: medication.dosage.pillsPerDose,
      notes: notes,
      createdAt: existingLog?.createdAt ?? now,
    );

    if (existingLog != null) {
      await _doseLogRepository.updateDoseLog(doseLog);
    } else {
      await _doseLogRepository.insertDoseLog(doseLog);
    }

    // Doz alındı, bu zaman diliminin bildirimini iptal et ve sonrakine planla
    await _cancelAndRescheduleDoseNotification(
      medication: medication,
      scheduledTime: scheduledTime,
    );

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

    final existingLog = await _doseLogRepository.findDoseLogByScheduledTime(
      medication.id,
      scheduledDateTime,
    );

    final doseLog = DoseLog(
      id: existingLog?.id ?? _uuid.v4(),
      medicationId: medication.id,
      scheduledTime: scheduledDateTime,
      status: DoseStatus.skipped,
      pillsTaken: 0,
      notes: notes,
      createdAt: existingLog?.createdAt ?? now,
    );

    if (existingLog != null) {
      await _doseLogRepository.updateDoseLog(doseLog);
    } else {
      await _doseLogRepository.insertDoseLog(doseLog);
    }

    // Doz atlandı, bu zaman diliminin bildirimini iptal et ve sonrakine planla
    await _cancelAndRescheduleDoseNotification(
      medication: medication,
      scheduledTime: scheduledTime,
    );

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
      if (!medication.dosage.isDueToday(today)) continue;

      if (medication.dosage.scheduleTimes.isEmpty) {
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

  /// Doz alındığında/atlandığında ilgili bildirimi iptal edip bir sonraki
  /// tekrar için yeniden planlar. Böylece alınmış doz için bildirim gitmez.
  Future<void> _cancelAndRescheduleDoseNotification({
    required Medication medication,
    required String scheduledTime,
  }) async {
    if (!medication.perDoseReminders) return;

    final times = medication.dosage.scheduleTimes.isNotEmpty
        ? medication.dosage.scheduleTimes
        : _generateDefaultTimes(medication.dosage.dosesPerDay);

    final timeIndex = times.indexOf(scheduledTime);
    if (timeIndex == -1) return;

    final freq = medication.dosage.frequencyType;
    int notificationSlotIndex;

    switch (freq) {
      case FrequencyType.daily:
      case FrequencyType.monthly:
        notificationSlotIndex = timeIndex;
      case FrequencyType.weekly:
        final today = DateTime.now().weekday;
        final weekdayIndex = medication.dosage.weeklyDays.indexOf(today);
        if (weekdayIndex == -1) return;
        notificationSlotIndex = weekdayIndex * times.length + timeIndex;
    }

    final notificationId = NotificationService.generateDoseNotificationId(
      medication.id,
      notificationSlotIndex,
    );

    await _notificationService.cancelNotification(notificationId);

    final parsedTime = AppDateUtils.parseTime(scheduledTime);
    if (parsedTime == null) return;

    await _notificationService.scheduleDoseReminder(
      medication: medication,
      hour: parsedTime.hour,
      minute: parsedTime.minute,
      notificationId: notificationId,
      frequencyType: freq,
      weekday: freq == FrequencyType.weekly ? DateTime.now().weekday : null,
      monthDay: freq == FrequencyType.monthly
          ? (medication.dosage.monthlyDay ?? 1)
          : null,
      forceNextOccurrence: true,
    );

    if (kDebugMode) {
      debugPrint(
        'Dose notification cancelled & rescheduled for next occurrence: '
        '${medication.name} at $scheduledTime',
      );
    }
  }

  /// Doz hatırlatıcılarını frekansa göre programla.
  /// [loggedTimesToday]: bugün zaten alınmış/atlanmış olan "HH:mm" saatleri.
  /// Bu saatler için bildirim bir sonraki güne/haftaya/aya ertelenir.
  Future<void> _scheduleDoseReminders(
    Medication medication, {
    Set<String> loggedTimesToday = const {},
  }) async {
    if (!medication.perDoseReminders) return;

    final times = medication.dosage.scheduleTimes.isNotEmpty
        ? medication.dosage.scheduleTimes
        : _generateDefaultTimes(medication.dosage.dosesPerDay);

    final freq = medication.dosage.frequencyType;

    switch (freq) {
      case FrequencyType.daily:
        for (int i = 0; i < times.length; i++) {
          final parsedTime = AppDateUtils.parseTime(times[i]);
          if (parsedTime == null) continue;
          final notificationId = NotificationService.generateDoseNotificationId(
            medication.id, i,
          );
          await _notificationService.scheduleDoseReminder(
            medication: medication,
            hour: parsedTime.hour,
            minute: parsedTime.minute,
            notificationId: notificationId,
            frequencyType: FrequencyType.daily,
            forceNextOccurrence: loggedTimesToday.contains(times[i]),
          );
        }

      case FrequencyType.weekly:
        int slotIndex = 0;
        for (final weekday in medication.dosage.weeklyDays) {
          for (int i = 0; i < times.length; i++) {
            final parsedTime = AppDateUtils.parseTime(times[i]);
            if (parsedTime == null) continue;
            final notificationId = NotificationService.generateDoseNotificationId(
              medication.id, slotIndex,
            );
            await _notificationService.scheduleDoseReminder(
              medication: medication,
              hour: parsedTime.hour,
              minute: parsedTime.minute,
              notificationId: notificationId,
              frequencyType: FrequencyType.weekly,
              weekday: weekday,
              forceNextOccurrence: loggedTimesToday.contains(times[i]),
            );
            slotIndex++;
          }
        }

      case FrequencyType.monthly:
        final day = medication.dosage.monthlyDay ?? 1;
        for (int i = 0; i < times.length; i++) {
          final parsedTime = AppDateUtils.parseTime(times[i]);
          if (parsedTime == null) continue;
          final notificationId = NotificationService.generateDoseNotificationId(
            medication.id, i,
          );
          await _notificationService.scheduleDoseReminder(
            medication: medication,
            hour: parsedTime.hour,
            minute: parsedTime.minute,
            notificationId: notificationId,
            frequencyType: FrequencyType.monthly,
            monthDay: day,
            forceNextOccurrence: loggedTimesToday.contains(times[i]),
          );
        }
    }
  }

  /// Tüm ilaçların bildirimlerini yeniden programla (uygulama açılışında çağrılır).
  /// Bugün zaten alınmış/atlanmış dozlar için bildirim bir sonraki periyoda ertelenir.
  Future<void> rescheduleAllNotifications() async {
    await _notificationService.cancelAllNotifications();

    final medications = await _medicationRepository.getAllMedications();
    final today = DateTime.now();

    for (final medication in medications) {
      final todayLogs = await _doseLogRepository.getDoseLogsByMedicationAndDate(
        medication.id,
        today,
      );
      final loggedTimes = todayLogs
          .where((log) => log.scheduledTime != null)
          .map((log) {
            final t = log.scheduledTime!;
            return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          })
          .toSet();

      await _scheduleDoseReminders(medication, loggedTimesToday: loggedTimes);
    }

    if (kDebugMode) {
      debugPrint('All notifications rescheduled for ${medications.length} medications');
    }
  }

  /// Stok kontrolü ve bildirim
  Future<void> _checkAndNotifyStock(Medication medication) async {
    final now = DateTime.now();
    final lastNotified = medication.lastNotified;

    // 5 gün kala uyarısı
    if (medication.estimatedDaysLeft <= medication.firstRunoutWarningDays && medication.estimatedDaysLeft > 0) {
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
