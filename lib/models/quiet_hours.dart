/// Sessiz saatler modeli
class QuietHours {
  /// Başlangıç saati (HH:mm)
  final String start;
  
  /// Bitiş saati (HH:mm)
  final String end;
  
  /// Aktif mi
  final bool enabled;

  const QuietHours({
    required this.start,
    required this.end,
    this.enabled = false,
  });

  /// Varsayılan sessiz saatler (22:00 - 08:00)
  factory QuietHours.defaultHours() {
    return const QuietHours(
      start: '22:00',
      end: '08:00',
      enabled: false,
    );
  }

  /// JSON'dan oluşturma
  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      start: json['start'] as String? ?? '22:00',
      end: json['end'] as String? ?? '08:00',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  /// JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'enabled': enabled,
    };
  }

  /// Verilen saat sessiz saatlerde mi kontrolü
  bool isInQuietHours(DateTime time) {
    if (!enabled) return false;
    
    final timeParts = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    // Gece yarısını geçen sessiz saatler için
    if (start.compareTo(end) > 0) {
      // Örn: 22:00 - 08:00
      return timeParts.compareTo(start) >= 0 || timeParts.compareTo(end) < 0;
    } else {
      // Normal aralık: Örn: 14:00 - 16:00
      return timeParts.compareTo(start) >= 0 && timeParts.compareTo(end) < 0;
    }
  }

  /// Kopyalama
  QuietHours copyWith({
    String? start,
    String? end,
    bool? enabled,
  }) {
    return QuietHours(
      start: start ?? this.start,
      end: end ?? this.end,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  String toString() => 'QuietHours(start: $start, end: $end, enabled: $enabled)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuietHours &&
        other.start == start &&
        other.end == end &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(start, end, enabled);
}
