import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ilac_takip/services/medication_service.dart';
import 'package:ilac_takip/services/notification_service.dart';

/// Arka plan görev isimleri
class BackgroundTaskNames {
  BackgroundTaskNames._();

  static const String checkMissedDoses = 'check-missed-doses';
}

/// Arka plan görev yöneticisi
class BackgroundService {
  BackgroundService._();

  static final BackgroundService _instance = BackgroundService._();
  static BackgroundService get instance => _instance;

  bool _isInitialized = false;

  /// Arka plan görevlerini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('BackgroundService initialized');
    }
  }

  /// Kaçırılmış doz kontrolü için periyodik görev planla
  Future<void> scheduleMissedDoseCheck() async {
    if (!_isInitialized) await initialize();

    await Workmanager().registerPeriodicTask(
      'medication-check-missed-doses',
      BackgroundTaskNames.checkMissedDoses,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    if (kDebugMode) {
      debugPrint('Scheduled periodic missed dose check');
    }
  }

  /// Tüm arka plan görevlerini iptal et
  Future<void> cancelAllTasks() async {
    if (!_isInitialized) await initialize();
    await Workmanager().cancelAll();

    if (kDebugMode) {
      debugPrint('Cancelled all background tasks');
    }
  }
}

/// Workmanager callback dispatcher
///
/// Not: Bu fonksiyon top-level olmalı ve static olmamalıdır.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) {
      debugPrint('Background task executed: $task');
    }

    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Bildirim servisini başlat
      await NotificationService.instance.initialize();

      switch (task) {
        case BackgroundTaskNames.checkMissedDoses:
          await _checkMissedDoses();
          break;
        default:
          if (kDebugMode) {
            debugPrint('Unknown background task: $task');
          }
      }

      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Background task error: $e');
      }
      return Future.value(false);
    }
  });
}

Future<void> _checkMissedDoses() async {
  final medicationService = MedicationService();
  await medicationService.checkMissedDoses();

  if (kDebugMode) {
    debugPrint('Background missed dose check completed');
  }
}
