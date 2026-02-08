import 'dart:convert';
import 'package:ilac_takip/core/constants/app_constants.dart';
import 'package:ilac_takip/models/dosage.dart';
import 'package:ilac_takip/models/quiet_hours.dart';
import 'package:ilac_takip/models/last_notified.dart';

/// İlaç alım türü (aç/tok/farketmez)
enum IntakeType {
  empty,    // Aç karnına
  full,     // Tok karnına
  either,   // Farketmez
}

extension IntakeTypeExtension on IntakeType {
  String get displayName {
    switch (this) {
      case IntakeType.empty:
        return 'Aç Karnına';
      case IntakeType.full:
        return 'Tok Karnına';
      case IntakeType.either:
        return 'Farketmez';
    }
  }
  
  String get shortName {
    switch (this) {
      case IntakeType.empty:
        return 'Aç';
      case IntakeType.full:
        return 'Tok';
      case IntakeType.either:
        return '';
    }
  }
  
  String get icon {
    switch (this) {
      case IntakeType.empty:
        return '🍽️';
      case IntakeType.full:
        return '🍔';
      case IntakeType.either:
        return '⏰';
    }
  }
}

/// İlaç modeli
class Medication {
  final String id;
  final String? userId;
  final String name;
  final int currentStock;
  final DateTime startDate;
  final Dosage dosage;
  final int lowStockThreshold;
  final int firstRunoutWarningDays;
  final bool perDoseReminders;
  final QuietHours quietHours;
  final String? notes;
  final DateTime? expirationDate;
  final LastNotified lastNotified;
  final IntakeType intakeType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    this.userId,
    required this.name,
    required this.currentStock,
    required this.startDate,
    required this.dosage,
    this.lowStockThreshold = AppConstants.defaultLowStockThreshold,
    this.firstRunoutWarningDays = AppConstants.defaultFirstRunoutWarningDays,
    this.perDoseReminders = true,
    this.quietHours = const QuietHours(start: '22:00', end: '08:00'),
    this.notes,
    this.expirationDate,
    this.lastNotified = const LastNotified(),
    this.intakeType = IntakeType.either,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Günlük tüketim
  int get dailyConsumption => dosage.dailyConsumption;

  /// Tahmini kalan gün sayısı
  int get estimatedDaysLeft {
    if (dailyConsumption <= 0) return 999; // Sonsuz
    return (currentStock / dailyConsumption).floor();
  }

  /// Düşük stokta mı
  bool get isLowStock => currentStock <= lowStockThreshold;

  /// Stok kritik mi (<=1 gün kaldı)
  bool get isCriticalStock => estimatedDaysLeft <= 1;

  /// Bitme uyarısı gösterilmeli mi (5 gün kala)
  bool get shouldShowRunoutWarning => estimatedDaysLeft <= firstRunoutWarningDays;

  /// Süresi dolmuş mu
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Stok tükendi mi
  bool get isOutOfStock => currentStock <= 0;

  /// Database'den oluşturma
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      userId: map['userId'] as String?,
      name: map['name'] as String,
      currentStock: map['currentStock'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      dosage: Dosage.fromJson({
        'pillsPerDose': map['pillsPerDose'],
        'dosesPerDay': map['dosesPerDay'],
        'scheduleTimes': map['scheduleTimes'],
      }),
      lowStockThreshold: map['lowStockThreshold'] as int? ?? AppConstants.defaultLowStockThreshold,
      firstRunoutWarningDays: map['firstRunoutWarningDays'] as int? ?? AppConstants.defaultFirstRunoutWarningDays,
      perDoseReminders: (map['perDoseReminders'] as int? ?? 1) == 1,
      quietHours: map['quietHoursStart'] != null
          ? QuietHours(
              start: map['quietHoursStart'] as String,
              end: map['quietHoursEnd'] as String,
              enabled: (map['quietHoursEnabled'] as int? ?? 0) == 1,
            )
          : QuietHours.defaultHours(),
      notes: map['notes'] as String?,
      expirationDate: map['expirationDate'] != null
          ? DateTime.parse(map['expirationDate'] as String)
          : null,
      lastNotified: map['lastNotifiedJson'] != null
          ? LastNotified.fromJson(jsonDecode(map['lastNotifiedJson'] as String))
          : const LastNotified(),
      intakeType: IntakeType.values.firstWhere(
        (e) => e.name == (map['intakeType'] as String? ?? 'either'),
        orElse: () => IntakeType.either,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Database'e kaydetme için Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'currentStock': currentStock,
      'startDate': startDate.toIso8601String(),
      'pillsPerDose': dosage.pillsPerDose,
      'dosesPerDay': dosage.dosesPerDay,
      'scheduleTimes': jsonEncode(dosage.scheduleTimes),
      'lowStockThreshold': lowStockThreshold,
      'firstRunoutWarningDays': firstRunoutWarningDays,
      'perDoseReminders': perDoseReminders ? 1 : 0,
      'quietHoursStart': quietHours.start,
      'quietHoursEnd': quietHours.end,
      'quietHoursEnabled': quietHours.enabled ? 1 : 0,
      'notes': notes,
      'expirationDate': expirationDate?.toIso8601String(),
      'lastNotifiedJson': jsonEncode(lastNotified.toJson()),
      'intakeType': intakeType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Kopyalama
  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    int? currentStock,
    DateTime? startDate,
    Dosage? dosage,
    int? lowStockThreshold,
    int? firstRunoutWarningDays,
    bool? perDoseReminders,
    QuietHours? quietHours,
    String? notes,
    DateTime? expirationDate,
    LastNotified? lastNotified,
    IntakeType? intakeType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearNotes = false,
    bool clearExpirationDate = false,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      startDate: startDate ?? this.startDate,
      dosage: dosage ?? this.dosage,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      firstRunoutWarningDays: firstRunoutWarningDays ?? this.firstRunoutWarningDays,
      perDoseReminders: perDoseReminders ?? this.perDoseReminders,
      quietHours: quietHours ?? this.quietHours,
      notes: clearNotes ? null : (notes ?? this.notes),
      expirationDate: clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      lastNotified: lastNotified ?? this.lastNotified,
      intakeType: intakeType ?? this.intakeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, currentStock: $currentStock, estimatedDaysLeft: $estimatedDaysLeft)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
