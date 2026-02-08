import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/models/dose_log.dart';

/// Programlanmış doz modeli (UI için)
/// Bir ilacın belirli bir saatteki dozunu temsil eder
class ScheduledDose {
  final Medication medication;
  final String scheduledTime; // HH:mm formatında
  final DateTime scheduledDateTime;
  final DoseLog? doseLog; // Eğer kayıt varsa

  const ScheduledDose({
    required this.medication,
    required this.scheduledTime,
    required this.scheduledDateTime,
    this.doseLog,
  });

  /// Alınmış mı
  bool get isTaken => doseLog?.isTaken ?? false;

  /// Kaçırılmış mı
  bool get isMissed => doseLog?.isMissed ?? false;

  /// Atlanmış mı
  bool get isSkipped => doseLog?.isSkipped ?? false;

  /// Beklemede mi (henüz işlem yapılmamış)
  bool get isPending => doseLog == null;

  /// Zamanı geçmiş mi
  bool get isPastDue {
    if (!isPending) return false;
    return DateTime.now().isAfter(scheduledDateTime);
  }

  /// Grace period içinde mi (60 dakika)
  bool get isWithinGracePeriod {
    if (!isPastDue) return false;
    final gracePeriodEnd = scheduledDateTime.add(const Duration(minutes: 60));
    return DateTime.now().isBefore(gracePeriodEnd);
  }

  /// Durum metni
  String get statusText {
    if (isTaken) return 'Alındı';
    if (isMissed) return 'Kaçırıldı';
    if (isSkipped) return 'Atlandı';
    if (isPastDue) return 'Gecikti';
    return 'Bekliyor';
  }

  @override
  String toString() {
    return 'ScheduledDose(medication: ${medication.name}, time: $scheduledTime, status: $statusText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledDose &&
        other.medication.id == medication.id &&
        other.scheduledTime == scheduledTime &&
        other.scheduledDateTime == scheduledDateTime;
  }

  @override
  int get hashCode => Object.hash(medication.id, scheduledTime, scheduledDateTime);
}
