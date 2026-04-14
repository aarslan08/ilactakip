import 'dart:convert';

/// İlaç kullanım sıklığı
enum FrequencyType {
  daily,   // Her gün
  weekly,  // Haftanın belirli günleri
  monthly, // Ayın belirli günü
}

/// Dozaj bilgisi modeli
class Dosage {
  /// Doz başına hap sayısı
  final int pillsPerDose;
  
  /// Günlük doz sayısı (o gün alındığında kaç kez)
  final int dosesPerDay;
  
  /// Programlı saat listesi (HH:mm formatında)
  final List<String> scheduleTimes;

  /// Kullanım sıklığı
  final FrequencyType frequencyType;

  /// Haftalık: hangi günlerde alınacak (1=Pazartesi..7=Pazar)
  final List<int> weeklyDays;

  /// Aylık: ayın hangi günü alınacak (1-31)
  final int? monthlyDay;

  const Dosage({
    required this.pillsPerDose,
    required this.dosesPerDay,
    this.scheduleTimes = const [],
    this.frequencyType = FrequencyType.daily,
    this.weeklyDays = const [],
    this.monthlyDay,
  });

  /// Tek alımda tüketilen ilaç (doz başına × günde kaç kez)
  int get perDayConsumption => pillsPerDose * dosesPerDay;

  /// Ortalama günlük tüketim (frekansa göre)
  double get dailyConsumptionRate {
    switch (frequencyType) {
      case FrequencyType.daily:
        return perDayConsumption.toDouble();
      case FrequencyType.weekly:
        if (weeklyDays.isEmpty) return 0;
        return (perDayConsumption * weeklyDays.length) / 7.0;
      case FrequencyType.monthly:
        return perDayConsumption / 30.0;
    }
  }

  /// Bugün doz alınması gerekiyor mu
  bool isDueToday([DateTime? date]) {
    final now = date ?? DateTime.now();
    switch (frequencyType) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.weekly:
        return weeklyDays.contains(now.weekday);
      case FrequencyType.monthly:
        return monthlyDay != null && now.day == monthlyDay;
    }
  }

  /// JSON'dan oluşturma
  factory Dosage.fromJson(Map<String, dynamic> json) {
    return Dosage(
      pillsPerDose: json['pillsPerDose'] as int? ?? 1,
      dosesPerDay: json['dosesPerDay'] as int? ?? 1,
      scheduleTimes: json['scheduleTimes'] != null
          ? List<String>.from(jsonDecode(json['scheduleTimes'] as String))
          : [],
      frequencyType: FrequencyType.values.firstWhere(
        (e) => e.name == (json['frequencyType'] as String? ?? 'daily'),
        orElse: () => FrequencyType.daily,
      ),
      weeklyDays: json['weeklyDays'] != null
          ? List<int>.from(jsonDecode(json['weeklyDays'] as String))
          : [],
      monthlyDay: json['monthlyDay'] as int?,
    );
  }

  /// JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'pillsPerDose': pillsPerDose,
      'dosesPerDay': dosesPerDay,
      'scheduleTimes': jsonEncode(scheduleTimes),
      'frequencyType': frequencyType.name,
      'weeklyDays': jsonEncode(weeklyDays),
      'monthlyDay': monthlyDay,
    };
  }

  /// Kopyalama
  Dosage copyWith({
    int? pillsPerDose,
    int? dosesPerDay,
    List<String>? scheduleTimes,
    FrequencyType? frequencyType,
    List<int>? weeklyDays,
    int? monthlyDay,
    bool clearMonthlyDay = false,
  }) {
    return Dosage(
      pillsPerDose: pillsPerDose ?? this.pillsPerDose,
      dosesPerDay: dosesPerDay ?? this.dosesPerDay,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      frequencyType: frequencyType ?? this.frequencyType,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthlyDay: clearMonthlyDay ? null : (monthlyDay ?? this.monthlyDay),
    );
  }

  @override
  String toString() {
    return 'Dosage(pillsPerDose: $pillsPerDose, dosesPerDay: $dosesPerDay, '
        'frequencyType: $frequencyType, scheduleTimes: $scheduleTimes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dosage &&
        other.pillsPerDose == pillsPerDose &&
        other.dosesPerDay == dosesPerDay &&
        other.frequencyType == frequencyType &&
        other.monthlyDay == monthlyDay &&
        _listEquals(other.scheduleTimes, scheduleTimes) &&
        _listEquals(other.weeklyDays, weeklyDays);
  }

  @override
  int get hashCode => Object.hash(
        pillsPerDose, dosesPerDay, frequencyType,
        scheduleTimes, weeklyDays, monthlyDay,
      );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
