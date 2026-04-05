import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/services/notification_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  
  Locale _locale = const Locale('tr');
  
  Locale get locale => _locale;
  
  LocaleProvider() {
    _loadLocale();
  }
  
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'tr';
    _locale = Locale(languageCode);
    _updateDateUtilsLocale();
    notifyListeners();
  }
  
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    _updateDateUtilsLocale();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  void _updateDateUtilsLocale() {
    final localeString = _locale.languageCode == 'en' ? 'en_US' : 'tr_TR';
    AppDateUtils.setLocale(localeString);
    NotificationService.setLocale(_locale.languageCode);
  }
  
  void setTurkish() => setLocale(const Locale('tr'));
  void setEnglish() => setLocale(const Locale('en'));
  
  bool get isTurkish => _locale.languageCode == 'tr';
  bool get isEnglish => _locale.languageCode == 'en';
  
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'tr':
      default:
        return 'Türkçe';
    }
  }
}
