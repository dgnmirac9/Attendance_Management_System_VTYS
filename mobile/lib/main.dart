import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'routes.dart';
import 'shared/themes/app_theme.dart';
import 'shared/themes/theme_manager.dart'; // Yeni oluşturduğumuz yönetici

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Kayıtlı Temayı Yükle
  await ThemeManager.loadTheme();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase hatası: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Temayı Dinleyen Yapı (ValueListenableBuilder)
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'C-LENS',
          debugShowCheckedModeBanner: false,
          
          // Temalar
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode, // Dinamik olarak burası değişecek

          // Rota
          initialRoute: Routes.login,
          onGenerateRoute: Routes.onGenerateRoute,
        );
      },
    );
  }
}