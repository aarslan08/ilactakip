/// Uygulama sabitleri
class AppConstants {
  AppConstants._();

  // Varsayılan değerler
  static const int defaultLowStockThreshold = 5;
  static const int defaultFirstRunoutWarningDays = 5;
  static const int defaultGracePeriodMinutes = 60;
  
  // Bildirim ID'leri
  static const int doseReminderNotificationId = 1000;
  static const int lowStockNotificationId = 2000;
  static const int runoutWarningNotificationId = 3000;
  
  // Database
  static const String databaseName = 'ilac_takip.db';
  static const int databaseVersion = 2;
  
  // Shared Preferences Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNotificationsEnabled = 'notifications_enabled';
}
