/// Son bildirim zamanları modeli
class LastNotified {
  /// 5 gün kala uyarısı son gönderilme zamanı
  final DateTime? runout5daysAt;
  
  /// Düşük stok uyarısı son gönderilme zamanı
  final DateTime? lowStockAt;
  
  /// Doz hatırlatıcısı son gönderilme zamanı
  final DateTime? doseReminderAt;

  const LastNotified({
    this.runout5daysAt,
    this.lowStockAt,
    this.doseReminderAt,
  });

  /// JSON'dan oluşturma
  factory LastNotified.fromJson(Map<String, dynamic> json) {
    return LastNotified(
      runout5daysAt: json['runout5daysAt'] != null
          ? DateTime.parse(json['runout5daysAt'] as String)
          : null,
      lowStockAt: json['lowStockAt'] != null
          ? DateTime.parse(json['lowStockAt'] as String)
          : null,
      doseReminderAt: json['doseReminderAt'] != null
          ? DateTime.parse(json['doseReminderAt'] as String)
          : null,
    );
  }

  /// JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'runout5daysAt': runout5daysAt?.toIso8601String(),
      'lowStockAt': lowStockAt?.toIso8601String(),
      'doseReminderAt': doseReminderAt?.toIso8601String(),
    };
  }

  /// Kopyalama
  LastNotified copyWith({
    DateTime? runout5daysAt,
    DateTime? lowStockAt,
    DateTime? doseReminderAt,
    bool clearRunout5days = false,
    bool clearLowStock = false,
    bool clearDoseReminder = false,
  }) {
    return LastNotified(
      runout5daysAt: clearRunout5days ? null : (runout5daysAt ?? this.runout5daysAt),
      lowStockAt: clearLowStock ? null : (lowStockAt ?? this.lowStockAt),
      doseReminderAt: clearDoseReminder ? null : (doseReminderAt ?? this.doseReminderAt),
    );
  }

  @override
  String toString() {
    return 'LastNotified(runout5daysAt: $runout5daysAt, lowStockAt: $lowStockAt, doseReminderAt: $doseReminderAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LastNotified &&
        other.runout5daysAt == runout5daysAt &&
        other.lowStockAt == lowStockAt &&
        other.doseReminderAt == doseReminderAt;
  }

  @override
  int get hashCode => Object.hash(runout5daysAt, lowStockAt, doseReminderAt);
}
