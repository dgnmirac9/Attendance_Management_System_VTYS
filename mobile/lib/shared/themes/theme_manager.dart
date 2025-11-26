import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Uygulamanın temasını dinleyen haberci (Varsayılan: Sistem ayarı)
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  // Temayı Kaydet ve Değiştir
  static Future<void> toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  // Uygulama açılınca hafızadan oku
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    
    if (isDark != null) {
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.system;
    }
  }
}