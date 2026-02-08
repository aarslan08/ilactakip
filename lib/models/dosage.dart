import 'dart:convert';

/// Dozaj bilgisi modeli
class Dosage {
  /// Doz başına hap sayısı
  final int pillsPerDose;
  
  /// Günlük doz sayısı
  final int dosesPerDay;
  
  /// Programlı saat listesi (HH:mm formatında)
  final List<String> scheduleTimes;

  const Dosage({
    required this.pillsPerDose,
    required this.dosesPerDay,
    this.scheduleTimes = const [],
  });

  /// Günlük tüketim hesaplama
  int get dailyConsumption => pillsPerDose * dosesPerDay;

  /// JSON'dan oluşturma
  factory Dosage.fromJson(Map<String, dynamic> json) {
    return Dosage(
      pillsPerDose: json['pillsPerDose'] as int? ?? 1,
      dosesPerDay: json['dosesPerDay'] as int? ?? 1,
      scheduleTimes: json['scheduleTimes'] != null
          ? List<String>.from(jsonDecode(json['scheduleTimes'] as String))
          : [],
    );
  }

  /// JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'pillsPerDose': pillsPerDose,
      'dosesPerDay': dosesPerDay,
      'scheduleTimes': jsonEncode(scheduleTimes),
    };
  }

  /// Kopyalama
  Dosage copyWith({
    int? pillsPerDose,
    int? dosesPerDay,
    List<String>? scheduleTimes,
  }) {
    return Dosage(
      pillsPerDose: pillsPerDose ?? this.pillsPerDose,
      dosesPerDay: dosesPerDay ?? this.dosesPerDay,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
    );
  }

  @override
  String toString() {
    return 'Dosage(pillsPerDose: $pillsPerDose, dosesPerDay: $dosesPerDay, scheduleTimes: $scheduleTimes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dosage &&
        other.pillsPerDose == pillsPerDose &&
        other.dosesPerDay == dosesPerDay &&
        _listEquals(other.scheduleTimes, scheduleTimes);
  }

  @override
  int get hashCode => Object.hash(pillsPerDose, dosesPerDay, scheduleTimes);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
