import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:ilac_takip/models/medication.dart';

/// Bildirim servisi
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;
  static String _currentLocale = 'tr';

  NotificationService._() : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  static void setLocale(String locale) {
    _currentLocale = locale;
  }

  static bool get _isEnglish => _currentLocale == 'en';

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('NotificationService initialized');
    }
  }

  /// Bildirim izinlerini iste
  Future<bool> requestPermissions() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Bildirime tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  /// Günlük tekrarlayan doz hatırlatıcısı programla
  Future<void> scheduleDailyDoseReminder({
    required Medication medication,
    required int hour,
    required int minute,
    required int notificationId,
  }) async {
    if (!medication.perDoseReminders) return;

    final testTime = DateTime(2024, 1, 1, hour, minute);
    if (medication.quietHours.isInQuietHours(testTime)) return;

    final androidDetails = AndroidNotificationDetails(
      'dose_reminders',
      _isEnglish ? 'Dose Reminders' : 'Doz Hatırlatıcıları',
      channelDescription: _isEnglish 
          ? 'Reminders for your medication doses' 
          : 'İlaç dozlarınız için hatırlatmalar',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF2E7D6B),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = _isEnglish ? '💊 Medication Time' : '💊 İlaç Zamanı';
    final body = _isEnglish 
        ? '${medication.name} - You need to take ${medication.dosage.pillsPerDose} pills'
        : '${medication.name} - ${medication.dosage.pillsPerDose} adet almanız gerekiyor';

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication:${medication.id}',
    );

    if (kDebugMode) {
      debugPrint('Daily dose reminder scheduled for ${medication.name} at $hour:$minute');
    }
  }

  /// Düşük stok bildirimi gönder
  Future<void> showLowStockNotification({
    required Medication medication,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'low_stock',
      _isEnglish ? 'Low Stock Alerts' : 'Düşük Stok Uyarıları',
      channelDescription: _isEnglish 
          ? 'Alerts when medication stock is low' 
          : 'İlaç stoğu azaldığında uyarılar',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF6B6B),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = _isEnglish ? '⚠️ Low Stock Warning' : '⚠️ Düşük Stok Uyarısı';
    final body = _isEnglish 
        ? 'Only ${medication.currentStock} units left for ${medication.name}. Time to refill!'
        : '${medication.name} için sadece ${medication.currentStock} adet kaldı. Yenileme zamanı!';

    final notifId = 200000 + medication.id.hashCode.abs() % 100000;
    await _notificationsPlugin.show(
      notifId,
      title,
      body,
      notificationDetails,
      payload: 'medication:${medication.id}',
    );

    if (kDebugMode) {
      debugPrint('Low stock notification shown for ${medication.name}');
    }
  }

  /// 5 gün kala uyarısı gönder
  Future<void> showRunoutWarningNotification({
    required Medication medication,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'runout_warning',
      _isEnglish ? 'Runout Warnings' : 'Bitme Uyarıları',
      channelDescription: _isEnglish 
          ? 'Warnings before medication runs out' 
          : 'İlaç bitmeden önce uyarılar',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFFB347),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = _isEnglish ? '📅 Medication Running Out' : '📅 İlaç Bitme Uyarısı';
    final body = _isEnglish 
        ? '${medication.name} will run out in approximately ${medication.estimatedDaysLeft} days. Plan your refill!'
        : '${medication.name} tahminen ${medication.estimatedDaysLeft} gün içinde bitecek. Yenilemeyi planlayın!';

    final notifId = 300000 + medication.id.hashCode.abs() % 100000;
    await _notificationsPlugin.show(
      notifId,
      title,
      body,
      notificationDetails,
      payload: 'medication:${medication.id}',
    );

    if (kDebugMode) {
      debugPrint('Runout warning notification shown for ${medication.name}');
    }
  }

  /// Kaçırılmış doz bildirimi gönder
  Future<void> showMissedDoseNotification({
    required Medication medication,
    required String scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'missed_dose',
      _isEnglish ? 'Missed Doses' : 'Kaçırılmış Dozlar',
      channelDescription: _isEnglish 
          ? 'Notifications for missed doses' 
          : 'Kaçırılmış dozlar için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFE53935),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = _isEnglish ? '❌ Missed Dose' : '❌ Kaçırılmış Doz';
    final body = _isEnglish 
        ? '${medication.name} - You missed your $scheduledTime dose'
        : '${medication.name} - $scheduledTime dozunu almadınız';

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: 'medication:${medication.id}',
    );

    if (kDebugMode) {
      debugPrint('Missed dose notification shown for ${medication.name}');
    }
  }

  /// Belirli bir ilaç için tüm bildirimleri iptal et
  Future<void> cancelMedicationNotifications(String medicationId) async {
    final baseId = medicationId.hashCode.abs() % 100000;

    for (int i = 0; i < maxDoseTimesPerMedication; i++) {
      await _notificationsPlugin.cancel(baseId * 10 + i);
    }
    await _notificationsPlugin.cancel(200000 + baseId);
    await _notificationsPlugin.cancel(300000 + baseId);

    if (kDebugMode) {
      debugPrint('Notifications cancelled for medication: $medicationId');
    }
  }

  static const int maxDoseTimesPerMedication = 8;

  /// Medication + time slot için deterministik bildirim ID'si üret
  static int generateDoseNotificationId(String medicationId, int timeIndex) {
    final baseId = medicationId.hashCode.abs() % 100000;
    return baseId * 10 + timeIndex;
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();

    if (kDebugMode) {
      debugPrint('All notifications cancelled');
    }
  }

  /// Bekleyen bildirimleri getir
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
