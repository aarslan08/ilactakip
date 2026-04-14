import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'appName': 'Medication Tracker',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'comingSoon': 'Coming soon',

      // Navigation
      'home': 'Home',
      'myMedications': 'My Medications',
      'history': 'History',
      'settings': 'Settings',

      // Home Screen
      'goodMorning': 'Good Morning ☀️',
      'goodAfternoon': 'Good Afternoon 🌤️',
      'goodEvening': 'Good Evening 🌆',
      'goodNight': 'Good Night 🌙',
      'today': 'Today',
      'todaysDoses': 'Today\'s Doses',
      'adherenceRate': 'Adherence Rate',
      'todaysSchedule': 'Today\'s Schedule',
      'viewAll': 'View All',
      'noDosesScheduled': 'No doses scheduled for today',
      'lowStockWarning': 'Low Stock Warning',
      'medicationsLowStock': 'medications are running low',
      'medicationTime': 'Medication Time!',
      'pendingDoses': 'pending doses',
      'start': 'Start',

      // Swipe Screen
      'swipeLeft': 'Skip',
      'swipeRight': 'Taken',
      'taken': 'TAKEN',
      'skip': 'SKIP',
      'takenStatus': 'Taken',
      'skippedStatus': 'Skipped',
      'missedStatus': 'Missed',
      'pendingStatus': 'Pending',
      'lateStatus': 'Late',
      'yourProgress': 'Your Progress',
      'allDone': 'All Done!',
      'greatJob': 'Great! 🎉',
      'allMedicationsTaken': 'You\'ve taken all your medications today.\nStay healthy!',
      'backToHome': 'Back to Home',
      'markedAsTaken': 'marked as taken',
      'wasSkipped': 'was skipped',

      // Medications
      'addMedication': 'Add Medication',
      'editMedication': 'Edit Medication',
      'medicationName': 'Medication Name',
      'medicationNameHint': 'e.g. Paracetamol 500mg',
      'currentStock': 'Current Stock',
      'stockHint': 'Number of units',
      'units': 'units',
      'pillsPerDose': 'Per Dose',
      'dosesPerDay': 'Daily Doses',
      'times': 'times',
      'doseTimes': 'Dose Times',
      'addTime': 'Add Time',
      'noTimeAdded': 'No time added (optional)',
      'medicationInfo': 'Medication Info',
      'dosageInfo': 'Dosage Info',
      'reminderSettings': 'Reminder Settings',
      'additionalInfo': 'Additional Info',
      'doseReminders': 'Dose Reminders',
      'getNotified': 'Get notified when it\'s time',
      'lowStockAlert': 'Low Stock Alert',
      'alertWhenLow': 'Alert when stock is low',
      'runoutWarning': 'Runout Warning',
      'daysBeforeRunout': 'days before runout',
      'expirationDate': 'Expiration Date',
      'selectDate': 'Select date (optional)',
      'notes': 'Notes (optional)',
      'notesHint': 'Additional information...',
      'saveChanges': 'Save Changes',
      'medicationAdded': 'Medication added',
      'medicationUpdated': 'Medication updated',
      'medicationDeleted': 'Medication deleted',
      'required': 'Required',
      'atLeast1': 'At least 1',
      'validNumber': 'Enter a valid number',
      'left': 'left',
      'estimatedDays': 'Estimated days',
      'noMedications': 'No Medications Yet',
      'addFirstMedication': 'Add your first medication to start tracking. Never miss a dose!',
      
      // Intake Type
      'whenToTake': 'When to Take?',
      'onEmptyStomach': 'On Empty Stomach',
      'onFullStomach': 'On Full Stomach',
      'anytime': 'Anytime',
      'empty': 'Empty',
      'full': 'Full',

      // Settings
      'settingsTitle': 'Settings',
      'managePreferences': 'Manage your preferences',
      'notifications': 'Notifications',
      'enableNotifications': 'Enable Notifications',
      'medicationReminders': 'Medication reminders and alerts',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'turkish': 'Turkish',
      'english': 'English',
      'about': 'About',
      'version': 'Version',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'support': 'Support',
      'sendFeedback': 'Send Feedback',
      'rateApp': 'Rate App',
      'languageChanged': 'Language changed',

      // Theme
      'theme': 'Theme',
      'selectTheme': 'Select Theme',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'systemTheme': 'System',
      'lightThemeDesc': 'Always use light theme',
      'darkThemeDesc': 'Always use dark theme',
      'systemThemeDesc': 'Follow system setting',
      'themeChanged': 'Theme changed',

      // Onboarding
      'onboardingTitle1': 'Track Your Medications',
      'onboardingDesc1': 'Add your medications, manage doses and monitor stock levels easily.',
      'onboardingTitle2': 'Dose Reminders',
      'onboardingDesc2': 'Get timely notifications and mark your doses with a simple swipe.',
      'onboardingTitle3': 'See Your Statistics',
      'onboardingDesc3': 'Track weekly and monthly adherence charts to stay on top of your health.',
      'onboardingGetStarted': 'Get Started',
      'onboardingSkip': 'Skip',
      'onboardingNext': 'Next',

      // Coach Marks
      'coachAdherenceTitle': 'Adherence Rate',
      'coachAdherenceDesc': 'See your daily adherence rate here. Tap for detailed statistics.',
      'coachDosesTitle': 'Today\'s Doses',
      'coachDosesDesc': 'Track how many doses you\'ve taken today out of total.',
      'coachQuickActionTitle': 'Quick Dose',
      'coachQuickActionDesc': 'Tap to quickly swipe through your pending doses.',
      'coachScheduleTitle': 'Dose Schedule',
      'coachScheduleDesc': 'Your daily dose cards. Tap Take or Skip for each one.',
      'coachMedicationsTitle': 'My Medications',
      'coachMedicationsDesc': 'Manage your medications, add new ones or update stock.',
      'coachHistoryTitle': 'History',
      'coachHistoryDesc': 'Review your past dose history day by day.',
      'coachSettingsTitle': 'Settings',
      'coachSettingsDesc': 'Change language, theme and notification preferences.',
      'coachGotIt': 'Got it',
      'coachNextStep': 'Next',
      'coachStepOf': 'of',
      'showTutorial': 'Show Tutorial',
      'showTutorialDesc': 'Watch the app guide again',
      'tutorialReset': 'Tutorial will show on next launch',

      // Statistics
      'statisticsTitle': 'Statistics',
      'weeklyView': 'Weekly',
      'monthlyView': 'Monthly',
      'adherenceByMedication': 'By Medication',
      'totalDosesTaken': 'Taken',
      'totalDosesMissed': 'Missed',
      'totalDosesSkipped': 'Skipped',
      'overallAdherence': 'Overall Adherence',
      'noDataYet': 'No data available yet',
      'tapForDetails': 'Tap for details',
      'dosesCount': 'doses',

      // History / Logs
      'doseHistory': 'Dose History',
      'noHistory': 'No History Yet',
      'historyWillAppear': 'Your medication history will appear here',
      'takenAt': 'Taken at',
      'unknownMedication': 'Unknown Medication',
      'todayLabel': 'Today',
      'yesterdayLabel': 'Yesterday',
      
      // Progress
      'todaysProgress': 'Today\'s Progress',
      'allDosesTaken': 'You\'ve taken all your medications today.\nStay healthy!',
      'pills': 'pills',
      'remaining': 'remaining',
      'overdue': 'Overdue!',
      
      // Medication Detail
      'medicationDetails': 'Medication Details',
      'deleteMedication': 'Delete Medication',
      'deleteMedicationConfirm': 'Are you sure you want to delete this medication? This action cannot be undone.',
      'stockStatus': 'Stock Status',
      'daysSupply': 'days supply',
      'schedule': 'Schedule',
      'noSchedule': 'No scheduled times',
      'daily': 'Daily',
      'timesPerDay': 'times per day',
      'intakeInstructions': 'Intake Instructions',
      'notificationSettings': 'Notification Settings',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'expiresOn': 'Expires on',
      'notSet': 'Not set',
      
      // Medication Card
      'pillsPerDayFormat': 'pills × daily doses',
      'lowStock': 'Low',
      'daysRemaining': 'days',
      'dose': 'dose',
      'doses': 'doses',

      // Frequency
      'frequency': 'Frequency',
      'frequencyDaily': 'Daily',
      'frequencyWeekly': 'Weekly',
      'frequencyMonthly': 'Monthly',
      'selectDays': 'Select Days',
      'dayOfMonth': 'Day of Month',
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
      'mondayFull': 'Monday',
      'tuesdayFull': 'Tuesday',
      'wednesdayFull': 'Wednesday',
      'thursdayFull': 'Thursday',
      'fridayFull': 'Friday',
      'saturdayFull': 'Saturday',
      'sundayFull': 'Sunday',
      'selectAtLeastOneDay': 'Select at least one day',
      'dosesOnScheduledDays': 'Doses on scheduled days',
      'everyDay': 'Every day',
      'weeklyDaysFormat': 'Weekly',
      'monthlyDayFormat': 'Monthly - Day',
    },
    'tr': {
      // Genel
      'appName': 'İlaç Takip',
      'save': 'Kaydet',
      'cancel': 'İptal',
      'delete': 'Sil',
      'edit': 'Düzenle',
      'add': 'Ekle',
      'close': 'Kapat',
      'yes': 'Evet',
      'no': 'Hayır',
      'ok': 'Tamam',
      'error': 'Hata',
      'success': 'Başarılı',
      'warning': 'Uyarı',
      'comingSoon': 'Yakında eklenecek',

      // Navigasyon
      'home': 'Ana Sayfa',
      'myMedications': 'İlaçlarım',
      'history': 'Geçmiş',
      'settings': 'Ayarlar',

      // Ana Ekran
      'goodMorning': 'Günaydın ☀️',
      'goodAfternoon': 'İyi Günler 🌤️',
      'goodEvening': 'İyi Akşamlar 🌆',
      'goodNight': 'İyi Geceler 🌙',
      'today': 'Bugün',
      'todaysDoses': 'Bugünkü Dozlar',
      'adherenceRate': 'Uyum Oranı',
      'todaysSchedule': 'Bugünkü Program',
      'viewAll': 'Tümü',
      'noDosesScheduled': 'Bugün için planlanmış doz yok',
      'lowStockWarning': 'Düşük Stok Uyarısı',
      'medicationsLowStock': 'ilacın stoğu azaldı',
      'medicationTime': 'İlaç Zamanı!',
      'pendingDoses': 'bekleyen doz var',
      'start': 'Başla',

      // Swipe Ekranı
      'swipeLeft': 'Atla',
      'swipeRight': 'Aldım',
      'taken': 'ALDIM',
      'skip': 'ATLA',
      'takenStatus': 'Alındı',
      'skippedStatus': 'Atlandı',
      'missedStatus': 'Kaçırıldı',
      'pendingStatus': 'Bekliyor',
      'lateStatus': 'Gecikti',
      'yourProgress': 'Bugünkü İlerlemen',
      'allDone': 'Tamamlandı!',
      'greatJob': 'Harika! 🎉',
      'allMedicationsTaken': 'Bugünkü tüm ilaçlarını aldın.\nSağlıklı günler!',
      'backToHome': 'Ana Sayfaya Dön',
      'markedAsTaken': 'alındı olarak işaretlendi',
      'wasSkipped': 'atlandı',

      // İlaçlar
      'addMedication': 'İlaç Ekle',
      'editMedication': 'İlacı Düzenle',
      'medicationName': 'İlaç Adı',
      'medicationNameHint': 'Örn: Paracetamol 500mg',
      'currentStock': 'Mevcut Stok',
      'stockHint': 'Adet sayısı',
      'units': 'adet',
      'pillsPerDose': 'Doz Başına',
      'dosesPerDay': 'Günlük Doz',
      'times': 'kez',
      'doseTimes': 'Doz Saatleri',
      'addTime': 'Saat Ekle',
      'noTimeAdded': 'Saat eklenmedi (opsiyonel)',
      'medicationInfo': 'İlaç Bilgileri',
      'dosageInfo': 'Dozaj Bilgileri',
      'reminderSettings': 'Hatırlatma Ayarları',
      'additionalInfo': 'Ek Bilgiler',
      'doseReminders': 'Doz Hatırlatıcıları',
      'getNotified': 'Zamanı gelince bildirim al',
      'lowStockAlert': 'Düşük Stok Uyarısı',
      'alertWhenLow': 'adet kaldığında uyar',
      'runoutWarning': 'Bitme Uyarısı',
      'daysBeforeRunout': 'gün kala uyar',
      'expirationDate': 'Son Kullanma Tarihi',
      'selectDate': 'Tarih seç (opsiyonel)',
      'notes': 'Notlar (opsiyonel)',
      'notesHint': 'Ek bilgiler...',
      'saveChanges': 'Değişiklikleri Kaydet',
      'medicationAdded': 'İlaç eklendi',
      'medicationUpdated': 'İlaç güncellendi',
      'medicationDeleted': 'İlaç silindi',
      'required': 'Gerekli',
      'atLeast1': 'En az 1',
      'validNumber': 'Geçerli bir sayı girin',
      'left': 'kaldı',
      'estimatedDays': 'Tahmini gün',
      'noMedications': 'İlaç Takibine Başlayın',
      'addFirstMedication': 'İlk ilacınızı ekleyerek düzenli ilaç takibine başlayın. Dozlarınızı asla kaçırmayın!',

      // Alım Türü
      'whenToTake': 'Ne Zaman Alınmalı?',
      'onEmptyStomach': 'Aç Karnına',
      'onFullStomach': 'Tok Karnına',
      'anytime': 'Farketmez',
      'empty': 'Aç',
      'full': 'Tok',

      // Ayarlar
      'settingsTitle': 'Ayarlar',
      'managePreferences': 'Uygulama tercihlerinizi yönetin',
      'notifications': 'Bildirimler',
      'enableNotifications': 'Bildirimleri Etkinleştir',
      'medicationReminders': 'İlaç hatırlatmaları ve uyarılar',
      'language': 'Dil',
      'selectLanguage': 'Dil Seçin',
      'turkish': 'Türkçe',
      'english': 'İngilizce',
      'about': 'Hakkında',
      'version': 'Versiyon',
      'privacyPolicy': 'Gizlilik Politikası',
      'termsOfService': 'Kullanım Koşulları',
      'support': 'Destek',
      'sendFeedback': 'Geri Bildirim Gönder',
      'rateApp': 'Uygulamayı Değerlendir',
      'languageChanged': 'Dil değiştirildi',

      // Tema
      'theme': 'Tema',
      'selectTheme': 'Tema Seçin',
      'lightTheme': 'Açık',
      'darkTheme': 'Koyu',
      'systemTheme': 'Sistem',
      'lightThemeDesc': 'Her zaman açık tema kullan',
      'darkThemeDesc': 'Her zaman koyu tema kullan',
      'systemThemeDesc': 'Sistem ayarını takip et',
      'themeChanged': 'Tema değiştirildi',

      // Onboarding
      'onboardingTitle1': 'İlaçlarını Takip Et',
      'onboardingDesc1': 'İlaçlarını ekle, dozlarını yönet ve stok durumunu kolayca izle.',
      'onboardingTitle2': 'Doz Hatırlatıcı',
      'onboardingDesc2': 'Zamanında bildirim al, basit bir kaydırma ile dozunu işaretle.',
      'onboardingTitle3': 'İstatistiklerini Gör',
      'onboardingDesc3': 'Haftalık ve aylık uyum grafiklerini takip ederek sağlığını kontrol altında tut.',
      'onboardingGetStarted': 'Başlayalım',
      'onboardingSkip': 'Atla',
      'onboardingNext': 'İleri',

      // Coach Marks
      'coachAdherenceTitle': 'Uyum Oranı',
      'coachAdherenceDesc': 'Günlük uyum oranınızı burada görün. Detaylı istatistikler için dokunun.',
      'coachDosesTitle': 'Bugünkü Dozlar',
      'coachDosesDesc': 'Bugün toplam dozlarınızdan kaçını aldığınızı buradan takip edin.',
      'coachQuickActionTitle': 'Hızlı Doz Al',
      'coachQuickActionDesc': 'Bekleyen dozlarınızı hızlıca kaydırmak için bu butona dokunun.',
      'coachScheduleTitle': 'Doz Programı',
      'coachScheduleDesc': 'Günlük doz kartlarınız. Her biri için Al veya Atla seçin.',
      'coachMedicationsTitle': 'İlaçlarım',
      'coachMedicationsDesc': 'İlaçlarınızı yönetin, yeni ilaç ekleyin veya stok güncelleyin.',
      'coachHistoryTitle': 'Geçmiş',
      'coachHistoryDesc': 'Geçmiş doz kayıtlarınızı günlük olarak inceleyin.',
      'coachSettingsTitle': 'Ayarlar',
      'coachSettingsDesc': 'Dil, tema ve bildirim tercihlerinizi buradan değiştirin.',
      'coachGotIt': 'Anladım',
      'coachNextStep': 'İleri',
      'coachStepOf': '/',
      'showTutorial': 'Rehberi Göster',
      'showTutorialDesc': 'Uygulama rehberini tekrar izle',
      'tutorialReset': 'Rehber bir sonraki açılışta gösterilecek',

      // İstatistikler
      'statisticsTitle': 'İstatistikler',
      'weeklyView': 'Haftalık',
      'monthlyView': 'Aylık',
      'adherenceByMedication': 'İlaç Bazlı',
      'totalDosesTaken': 'Alınan',
      'totalDosesMissed': 'Kaçırılan',
      'totalDosesSkipped': 'Atlanan',
      'overallAdherence': 'Genel Uyum',
      'noDataYet': 'Henüz veri yok',
      'tapForDetails': 'Detaylar için dokunun',
      'dosesCount': 'doz',

      // Geçmiş / Loglar
      'doseHistory': 'Doz Geçmişi',
      'noHistory': 'Henüz Geçmiş Yok',
      'historyWillAppear': 'İlaç geçmişiniz burada görünecek',
      'takenAt': 'Alındı',
      'unknownMedication': 'Bilinmeyen İlaç',
      'todayLabel': 'Bugün',
      'yesterdayLabel': 'Dün',
      
      // İlerleme
      'todaysProgress': 'Bugünkü İlerlemen',
      'allDosesTaken': 'Bugünkü tüm ilaçlarını aldın.\nSağlıklı günler!',
      'pills': 'adet',
      'remaining': 'kaldı',
      'overdue': 'Gecikti!',
      
      // İlaç Detayı
      'medicationDetails': 'İlaç Detayları',
      'deleteMedication': 'İlacı Sil',
      'deleteMedicationConfirm': 'Bu ilacı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      'stockStatus': 'Stok Durumu',
      'daysSupply': 'günlük stok',
      'schedule': 'Program',
      'noSchedule': 'Planlanmış saat yok',
      'daily': 'Günlük',
      'timesPerDay': 'kez',
      'intakeInstructions': 'Kullanım Talimatları',
      'notificationSettings': 'Bildirim Ayarları',
      'enabled': 'Açık',
      'disabled': 'Kapalı',
      'expiresOn': 'Son kullanma tarihi',
      'notSet': 'Belirtilmemiş',
      
      // İlaç Kartı
      'pillsPerDayFormat': 'adet × günde doz',
      'lowStock': 'Düşük',
      'daysRemaining': 'gün',
      'dose': 'doz',
      'doses': 'doz',

      // Frekans
      'frequency': 'Kullanım Sıklığı',
      'frequencyDaily': 'Günlük',
      'frequencyWeekly': 'Haftalık',
      'frequencyMonthly': 'Aylık',
      'selectDays': 'Günleri Seçin',
      'dayOfMonth': 'Ayın Günü',
      'monday': 'Pzt',
      'tuesday': 'Sal',
      'wednesday': 'Çar',
      'thursday': 'Per',
      'friday': 'Cum',
      'saturday': 'Cmt',
      'sunday': 'Paz',
      'mondayFull': 'Pazartesi',
      'tuesdayFull': 'Salı',
      'wednesdayFull': 'Çarşamba',
      'thursdayFull': 'Perşembe',
      'fridayFull': 'Cuma',
      'saturdayFull': 'Cumartesi',
      'sundayFull': 'Pazar',
      'selectAtLeastOneDay': 'En az bir gün seçin',
      'dosesOnScheduledDays': 'Belirlenen günlerde doz',
      'everyDay': 'Her gün',
      'weeklyDaysFormat': 'Haftalık',
      'monthlyDayFormat': 'Aylık - Gün',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Kısayol getter'lar
  String get appName => translate('appName');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get close => translate('close');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get comingSoon => translate('comingSoon');

  // Navigation
  String get home => translate('home');
  String get myMedications => translate('myMedications');
  String get history => translate('history');
  String get settings => translate('settings');

  // Home
  String get goodMorning => translate('goodMorning');
  String get goodAfternoon => translate('goodAfternoon');
  String get goodEvening => translate('goodEvening');
  String get goodNight => translate('goodNight');
  String get today => translate('today');
  String get todaysDoses => translate('todaysDoses');
  String get adherenceRate => translate('adherenceRate');
  String get todaysSchedule => translate('todaysSchedule');
  String get viewAll => translate('viewAll');
  String get noDosesScheduled => translate('noDosesScheduled');
  String get lowStockWarning => translate('lowStockWarning');
  String get medicationsLowStock => translate('medicationsLowStock');
  String get medicationTime => translate('medicationTime');
  String get pendingDoses => translate('pendingDoses');
  String get start => translate('start');

  // Swipe
  String get swipeLeft => translate('swipeLeft');
  String get swipeRight => translate('swipeRight');
  String get taken => translate('taken');
  String get skip => translate('skip');
  String get takenStatus => translate('takenStatus');
  String get skippedStatus => translate('skippedStatus');
  String get missedStatus => translate('missedStatus');
  String get pendingStatus => translate('pendingStatus');
  String get lateStatus => translate('lateStatus');
  String get yourProgress => translate('yourProgress');
  String get allDone => translate('allDone');
  String get greatJob => translate('greatJob');
  String get allMedicationsTaken => translate('allMedicationsTaken');
  String get backToHome => translate('backToHome');
  String get markedAsTaken => translate('markedAsTaken');
  String get wasSkipped => translate('wasSkipped');

  // Medications
  String get addMedication => translate('addMedication');
  String get editMedication => translate('editMedication');
  String get medicationName => translate('medicationName');
  String get medicationNameHint => translate('medicationNameHint');
  String get currentStock => translate('currentStock');
  String get stockHint => translate('stockHint');
  String get units => translate('units');
  String get pillsPerDose => translate('pillsPerDose');
  String get dosesPerDay => translate('dosesPerDay');
  String get times => translate('times');
  String get doseTimes => translate('doseTimes');
  String get addTime => translate('addTime');
  String get noTimeAdded => translate('noTimeAdded');
  String get medicationInfo => translate('medicationInfo');
  String get dosageInfo => translate('dosageInfo');
  String get reminderSettings => translate('reminderSettings');
  String get additionalInfo => translate('additionalInfo');
  String get doseReminders => translate('doseReminders');
  String get getNotified => translate('getNotified');
  String get lowStockAlert => translate('lowStockAlert');
  String get alertWhenLow => translate('alertWhenLow');
  String get runoutWarning => translate('runoutWarning');
  String get daysBeforeRunout => translate('daysBeforeRunout');
  String get expirationDate => translate('expirationDate');
  String get selectDate => translate('selectDate');
  String get notes => translate('notes');
  String get notesHint => translate('notesHint');
  String get saveChanges => translate('saveChanges');
  String get medicationAdded => translate('medicationAdded');
  String get medicationUpdated => translate('medicationUpdated');
  String get medicationDeleted => translate('medicationDeleted');
  String get required => translate('required');
  String get atLeast1 => translate('atLeast1');
  String get validNumber => translate('validNumber');
  String get left => translate('left');
  String get estimatedDays => translate('estimatedDays');
  String get noMedications => translate('noMedications');
  String get addFirstMedication => translate('addFirstMedication');

  // Intake Type
  String get whenToTake => translate('whenToTake');
  String get onEmptyStomach => translate('onEmptyStomach');
  String get onFullStomach => translate('onFullStomach');
  String get anytime => translate('anytime');
  String get empty => translate('empty');
  String get full => translate('full');

  // Settings
  String get settingsTitle => translate('settingsTitle');
  String get managePreferences => translate('managePreferences');
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enableNotifications');
  String get medicationReminders => translate('medicationReminders');
  String get language => translate('language');
  String get selectLanguage => translate('selectLanguage');
  String get turkish => translate('turkish');
  String get english => translate('english');
  String get about => translate('about');
  String get version => translate('version');
  String get privacyPolicy => translate('privacyPolicy');
  String get termsOfService => translate('termsOfService');
  String get support => translate('support');
  String get sendFeedback => translate('sendFeedback');
  String get rateApp => translate('rateApp');
  String get languageChanged => translate('languageChanged');

  // Theme
  String get theme => translate('theme');
  String get selectTheme => translate('selectTheme');
  String get lightTheme => translate('lightTheme');
  String get darkTheme => translate('darkTheme');
  String get systemTheme => translate('systemTheme');
  String get lightThemeDesc => translate('lightThemeDesc');
  String get darkThemeDesc => translate('darkThemeDesc');
  String get systemThemeDesc => translate('systemThemeDesc');
  String get themeChanged => translate('themeChanged');

  // Onboarding
  String get onboardingTitle1 => translate('onboardingTitle1');
  String get onboardingDesc1 => translate('onboardingDesc1');
  String get onboardingTitle2 => translate('onboardingTitle2');
  String get onboardingDesc2 => translate('onboardingDesc2');
  String get onboardingTitle3 => translate('onboardingTitle3');
  String get onboardingDesc3 => translate('onboardingDesc3');
  String get onboardingGetStarted => translate('onboardingGetStarted');
  String get onboardingSkip => translate('onboardingSkip');
  String get onboardingNext => translate('onboardingNext');

  // Coach Marks
  String get coachAdherenceTitle => translate('coachAdherenceTitle');
  String get coachAdherenceDesc => translate('coachAdherenceDesc');
  String get coachDosesTitle => translate('coachDosesTitle');
  String get coachDosesDesc => translate('coachDosesDesc');
  String get coachQuickActionTitle => translate('coachQuickActionTitle');
  String get coachQuickActionDesc => translate('coachQuickActionDesc');
  String get coachScheduleTitle => translate('coachScheduleTitle');
  String get coachScheduleDesc => translate('coachScheduleDesc');
  String get coachMedicationsTitle => translate('coachMedicationsTitle');
  String get coachMedicationsDesc => translate('coachMedicationsDesc');
  String get coachHistoryTitle => translate('coachHistoryTitle');
  String get coachHistoryDesc => translate('coachHistoryDesc');
  String get coachSettingsTitle => translate('coachSettingsTitle');
  String get coachSettingsDesc => translate('coachSettingsDesc');
  String get coachGotIt => translate('coachGotIt');
  String get coachNextStep => translate('coachNextStep');
  String get coachStepOf => translate('coachStepOf');
  String get showTutorial => translate('showTutorial');
  String get showTutorialDesc => translate('showTutorialDesc');
  String get tutorialReset => translate('tutorialReset');

  // Statistics
  String get statisticsTitle => translate('statisticsTitle');
  String get weeklyView => translate('weeklyView');
  String get monthlyView => translate('monthlyView');
  String get adherenceByMedication => translate('adherenceByMedication');
  String get totalDosesTaken => translate('totalDosesTaken');
  String get totalDosesMissed => translate('totalDosesMissed');
  String get totalDosesSkipped => translate('totalDosesSkipped');
  String get overallAdherence => translate('overallAdherence');
  String get noDataYet => translate('noDataYet');
  String get tapForDetails => translate('tapForDetails');
  String get dosesCount => translate('dosesCount');

  // History
  String get doseHistory => translate('doseHistory');
  String get noHistory => translate('noHistory');
  String get historyWillAppear => translate('historyWillAppear');
  String get takenAt => translate('takenAt');
  String get unknownMedication => translate('unknownMedication');
  String get todayLabel => translate('todayLabel');
  String get yesterdayLabel => translate('yesterdayLabel');

  // Progress
  String get todaysProgress => translate('todaysProgress');
  String get allDosesTaken => translate('allDosesTaken');
  String get pills => translate('pills');
  String get remaining => translate('remaining');
  String get overdue => translate('overdue');

  // Medication Detail
  String get medicationDetails => translate('medicationDetails');
  String get deleteMedication => translate('deleteMedication');
  String get deleteMedicationConfirm => translate('deleteMedicationConfirm');
  String get stockStatus => translate('stockStatus');
  String get daysSupply => translate('daysSupply');
  String get schedule => translate('schedule');
  String get noSchedule => translate('noSchedule');
  String get daily => translate('daily');
  String get timesPerDay => translate('timesPerDay');
  String get intakeInstructions => translate('intakeInstructions');
  String get notificationSettings => translate('notificationSettings');
  String get enabled => translate('enabled');
  String get disabled => translate('disabled');
  String get expiresOn => translate('expiresOn');
  String get notSet => translate('notSet');

  // Medication Card
  String get lowStock => translate('lowStock');
  String get daysRemaining => translate('daysRemaining');
  String get dose => translate('dose');
  String get doses => translate('doses');

  // Frequency
  String get frequency => translate('frequency');
  String get frequencyDaily => translate('frequencyDaily');
  String get frequencyWeekly => translate('frequencyWeekly');
  String get frequencyMonthly => translate('frequencyMonthly');
  String get selectDays => translate('selectDays');
  String get dayOfMonth => translate('dayOfMonth');
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');
  String get sunday => translate('sunday');
  String get mondayFull => translate('mondayFull');
  String get tuesdayFull => translate('tuesdayFull');
  String get wednesdayFull => translate('wednesdayFull');
  String get thursdayFull => translate('thursdayFull');
  String get fridayFull => translate('fridayFull');
  String get saturdayFull => translate('saturdayFull');
  String get sundayFull => translate('sundayFull');
  String get selectAtLeastOneDay => translate('selectAtLeastOneDay');
  String get dosesOnScheduledDays => translate('dosesOnScheduledDays');
  String get everyDay => translate('everyDay');
  String get weeklyDaysFormat => translate('weeklyDaysFormat');
  String get monthlyDayFormat => translate('monthlyDayFormat');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
