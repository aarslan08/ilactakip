/// Doz durumu enum
enum DoseStatus {
  taken('taken', 'Alındı'),
  missed('missed', 'Kaçırıldı'),
  skipped('skipped', 'Atlandı');

  final String value;
  final String label;

  const DoseStatus(this.value, this.label);

  static DoseStatus fromValue(String value) {
    return DoseStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DoseStatus.missed,
    );
  }
}

/// Doz kaydı modeli
class DoseLog {
  final String id;
  final String medicationId;
  final DateTime? scheduledTime;
  final DateTime? takenTime;
  final DoseStatus status;
  final int pillsTaken;
  final String? notes;
  final DateTime createdAt;

  const DoseLog({
    required this.id,
    required this.medicationId,
    this.scheduledTime,
    this.takenTime,
    required this.status,
    required this.pillsTaken,
    this.notes,
    required this.createdAt,
  });

  /// Alınmış mı
  bool get isTaken => status == DoseStatus.taken;

  /// Kaçırılmış mı
  bool get isMissed => status == DoseStatus.missed;

  /// Atlanmış mı
  bool get isSkipped => status == DoseStatus.skipped;

  /// Database'den oluşturma
  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as String,
      medicationId: map['medicationId'] as String,
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.parse(map['scheduledTime'] as String)
          : null,
      takenTime: map['takenTime'] != null
          ? DateTime.parse(map['takenTime'] as String)
          : null,
      status: DoseStatus.fromValue(map['status'] as String),
      pillsTaken: map['pillsTaken'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Database'e kaydetme için Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status.value,
      'pillsTaken': pillsTaken,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Kopyalama
  DoseLog copyWith({
    String? id,
    String? medicationId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    DoseStatus? status,
    int? pillsTaken,
    String? notes,
    DateTime? createdAt,
    bool clearScheduledTime = false,
    bool clearTakenTime = false,
    bool clearNotes = false,
  }) {
    return DoseLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
      takenTime: clearTakenTime ? null : (takenTime ?? this.takenTime),
      status: status ?? this.status,
      pillsTaken: pillsTaken ?? this.pillsTaken,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DoseLog(id: $id, medicationId: $medicationId, status: ${status.label}, pillsTaken: $pillsTaken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoseLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
