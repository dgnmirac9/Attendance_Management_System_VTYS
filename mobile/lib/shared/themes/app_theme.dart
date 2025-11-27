import 'package:flutter/material.dart';

class AppTheme {
  // --- ORTAK SABİTLER ---
  static const double _borderRadius = 16.0; // Standart Yuvarlaklık

  // --- MAVİ PALET: AÇIK TEMA RENKLERİ ---
  static const Color _lightPrimary = Color(0xFF1E88E5); // Mavi 600 (Güçlü Mavi)
  static const Color _lightBackground = Color(0xFFE3F2FD); // Mavi 50 (Çok Açık Zemin)
  static const Color _lightSurface = Colors.white; // Kartlar
  static const Color _lightTextPrimary = Color(0xFF1565C0); // Mavi 800 (Koyu Mavi Yazı)
  static const Color _lightBorder = Color(0xFFBBDEFB); // Mavi 100 (Pasif Çerçeve)

  // --- MAVİ PALET: KOYU TEMA RENKLERİ (Yüksek Kontrast) ---
  static const Color _darkPrimary = Color(0xFF64B5F6); // Mavi 300 (Koyu zeminde parlayan aksan)
  static const Color _darkBackground = Color(0xFF121212); // Klasik Koyu Zemin
  static const Color _darkSurface = Color(0xFF212121); // Kartlar
  // FIX: Koyu zeminde okunurluğu artırmak için Input kutularını bir tık daha açık yapıyoruz
  static const Color _darkInputFill = Color(0xFF2D3748); 
  static const Color _darkTextPrimary = Colors.white; // Yazı her zaman Beyaz
  static const Color _darkBorder = Color(0xFF424242); // Koyu Gri Çerçeve

  // ===========================================================================
  // AÇIK TEMA (Light)
  // ===========================================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPrimary,
        primary: _lightPrimary,
        surface: _lightSurface,
        onSurface: _lightTextPrimary,
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: _lightBackground,
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: _lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: _lightTextPrimary),
      ),

      // Form Alanları
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_borderRadius), borderSide: const BorderSide(color: _lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_borderRadius), borderSide: const BorderSide(color: _lightBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_borderRadius), borderSide: const BorderSide(color: _lightPrimary, width: 2.5)),
        labelStyle: TextStyle(color: _lightTextPrimary.withOpacity(0.7)),
        prefixIconColor: _lightPrimary,
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          side: const BorderSide(color: _lightPrimary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(_borderRadius * 1.5))),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_borderRadius))),
      ),
    );
  }

  // ===========================================================================
  // KOYU TEMA (Dark)
  // ===========================================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkPrimary,
        primary: _darkPrimary,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        brightness: Brightness.dark,
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: _darkBackground,

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: _darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: _darkTextPrimary),
      ),

      // FIX: Form Alanları
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkInputFill, // <-- DAHA AÇIK DOLGU RENGİ
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_borderRadius), borderSide: const BorderSide(color: _darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_borderRadius), borderSide: const BorderSide(color: _darkBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_borderRadius), borderSide: const BorderSide(color: _darkPrimary, width: 2.5)),
        labelStyle: TextStyle(color: _darkTextPrimary.withOpacity(0.7)),
        prefixIconColor: _darkPrimary,
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkBackground, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(_borderRadius * 1.5))),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _darkPrimary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_borderRadius))),
      ),
    );
  }
}