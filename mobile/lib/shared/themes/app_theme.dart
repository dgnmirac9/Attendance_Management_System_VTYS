import 'package:flutter/material.dart';

class AppTheme {
  // --- AÇIK TEMA RENKLERİ ---
  static const Color _lightPrimary = Color(0xFF1E88E5); 
  static const Color _lightBackground = Color(0xFFF0F4F8); 
  static const Color _lightSurface = Colors.white; 
  static const Color _lightTextPrimary = Color(0xFF1565C0); 
  static const Color _lightBorder = Color(0xFF90CAF9); 

  // --- KOYU TEMA RENKLERİ ---
  static const Color _darkPrimary = Color(0xFF90CAF9); 
  static const Color _darkBackground = Color(0xFF121212); 
  static const Color _darkSurface = Color(0xFF1E1E1E); 
  static const Color _darkTextPrimary = Color(0xFFE3F2FD); 
  static const Color _darkBorder = Color(0xFF424242); 

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
        error: Colors.red.shade600,
      ),
      scaffoldBackgroundColor: _lightBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: _lightTextPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: _lightTextPrimary),
      ),

      // Form Alanları
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _lightBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _lightPrimary, width: 2.5)),
        labelStyle: const TextStyle(color: _lightTextPrimary),
        prefixIconColor: _lightPrimary,
      ),

      // Butonlar (DÜZELTİLDİ: minimumSize EKLENDİ)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(double.infinity, 56), // <-- İŞTE BU EKSİKTİ
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          side: const BorderSide(color: _lightPrimary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(double.infinity, 56), // <-- İŞTE BU EKSİKTİ
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
        brightness: Brightness.dark,
        error: Colors.red.shade300,
      ),
      scaffoldBackgroundColor: _darkBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: _darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: _darkTextPrimary),
      ),

      // Form Alanları
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _darkBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _darkPrimary, width: 2.5)),
        labelStyle: const TextStyle(color: _darkTextPrimary),
        prefixIconColor: _darkPrimary,
      ),

      // Butonlar (DÜZELTİLDİ: minimumSize EKLENDİ)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkBackground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(double.infinity, 56), // <-- BURAYA DA EKLENDİ
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(double.infinity, 56), // <-- BURAYA DA EKLENDİ
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      ),
    );
  }
}