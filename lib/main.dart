import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/services/notification_service.dart';
import 'package:ilac_takip/ui/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatını başlat
  await initializeDateFormatting('tr_TR', null);

  // Bildirim servisini başlat
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // Sistem UI ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Sadece dikey yönlendirme
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'İlaç Takip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigation(),
      ),
    );
  }
}
