# 💊 İlaç Takip - Medication Tracker

Modern ve kullanıcı dostu bir ilaç takip uygulaması. İlaçlarınızı takip edin, dozlarınızı kaçırmayın ve stok durumunuzu kontrol altında tutun.

## 📱 Özellikler

### Ana Özellikler
- ✅ **Doz Takibi**: Günlük dozlarınızı takip edin, "Aldım" veya "Atla" seçenekleriyle işaretleyin
- 📊 **Stok Yönetimi**: Mevcut stok ve tahmini bitme süresini görüntüleyin
- 🔔 **Akıllı Bildirimler**: Doz saatlerinde, düşük stokta ve ilaç bitmeden önce uyarılar
- 📈 **Uyum Takibi**: Doz alma uyumunuzu (adherence) takip edin
- 🌙 **Karanlık Mod**: Sistem temasına uyumlu karanlık tema desteği
- 🌍 **Çoklu Dil Desteği**: Türkçe ve İngilizce arayüz desteği

### Bildirim Sistemi
1. **Doz Hatırlatıcıları**: Belirlenen saatlerde bildirim
2. **Düşük Stok Uyarısı**: Stok ≤5 adet olduğunda günlük uyarı
3. **Bitme Uyarısı**: Tahmini 5 gün kala tek seferlik uyarı
4. **Kaçırılmış Doz**: 60 dakika geçince bildirim

### Ekranlar
- 🏠 **Ana Sayfa**: Bugünkü dozlar ve hızlı istatistikler
- 💊 **İlaçlarım**: Tüm ilaçların listesi (arama desteği ile)
- 📋 **İlaç Detayı**: Detaylı bilgi, stok güncelleme, geçmiş
- ➕ **İlaç Ekle/Düzenle**: Kapsamlı form ile ilaç yönetimi
- 📜 **Geçmiş**: Doz kayıtları ve filtreleme ile uyum analizi
- 📊 **İstatistikler**: Haftalık/aylık uyum grafikleri
- ⚙️ **Ayarlar**: Tema, dil, bildirim ve destek bağlantıları
- 👆 **Hızlı Doz**: Kaydırarak doz alma/atlatma ekranı
- 🚀 **Onboarding**: İlk kullanım rehberi

## 🛠 Teknik Detaylar

### Mimari
- **UI / Logic Ayrımı**: Clean Architecture prensipleri
- **State Management**: Provider pattern
- **Local Database**: SQLite (sqflite)
- **Local Notifications**: flutter_local_notifications

### Veri Modelleri

#### Medication (İlaç)
```dart
- id, userId
- name (örn: "Paracetamol 500mg")
- currentStock (mevcut stok)
- startDate
- dosage:
    - pillsPerDose (doz başına adet)
    - dosesPerDay (günlük doz sayısı)
    - scheduleTimes (HH:mm listesi)
- lowStockThreshold (varsayılan: 5)
- firstRunoutWarningDays (varsayılan: 5)
- perDoseReminders (boolean)
- quietHours (start/end)
- notes, expirationDate
- lastNotified (son bildirim zamanları)
```

#### DoseLog (Doz Kaydı)
```dart
- id, medicationId
- scheduledTime, takenTime
- status (taken/missed/skipped)
- pillsTaken
- createdAt
```

### Hesaplamalar
```dart
dailyConsumption = pillsPerDose × dosesPerDay
estimatedDaysLeft = floor(currentStock / dailyConsumption)
```

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.2.0+
- Dart SDK 3.2.0+

### Bağımlılıkları Yükle
```bash
cd "ilaç takip"
flutter pub get
```

### Çalıştır
```bash
flutter run
```

### Build
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 📁 Proje Yapısı

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── localization/
│   │   └── app_localizations.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── date_utils.dart
├── data/
│   ├── database/
│   │   └── database_helper.dart
│   └── repositories/
│       ├── medication_repository.dart
│       └── dose_log_repository.dart
├── models/
│   ├── medication.dart
│   ├── dose_log.dart
│   ├── dosage.dart
│   ├── quiet_hours.dart
│   ├── last_notified.dart
│   └── scheduled_dose.dart
├── providers/
│   ├── medication_provider.dart
│   ├── theme_provider.dart
│   └── locale_provider.dart
├── services/
│   ├── notification_service.dart
│   └── medication_service.dart
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── medications_screen.dart
│   │   ├── medication_detail_screen.dart
│   │   ├── add_medication_screen.dart
│   │   ├── logs_screen.dart
│   │   ├── statistics_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── swipe_dose_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── legal_content_screen.dart
│   │   └── main_navigation.dart
│   └── widgets/
│       ├── dose_card.dart
│       ├── medication_card.dart
│       ├── empty_state.dart
│       ├── stats_card.dart
│       └── coach_mark_overlay.dart
└── main.dart
```

## 🎨 UI/UX

- **Tema**: Modern, temiz tasarım
- **Ana Renk**: Yeşil tonları (#2E7D6B)
- **Aksan Renk**: Mercan kırmızısı (#FF6B6B)
- **Animasyonlar**: Smooth geçişler ve etkileşimler
- **Yüksek Kontrast**: Okunabilirlik için optimize edilmiş metin renkleri

## 📋 Gelecek Özellikler

- [ ] Cloud sync (Firebase)
- [ ] Aile üyesi hesapları
- [ ] İlaç etkileşim uyarıları
- [ ] Doktor randevu takibi
- [ ] Export/Import özellikleri
- [ ] Widget desteği (Android/iOS)

## 📄 Lisans

MIT License - Dilediğiniz gibi kullanabilirsiniz.

---

Geliştirici: İlaç Takip Ekibi  
Sürüm: 1.0.0
