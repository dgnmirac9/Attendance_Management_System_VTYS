import 'package:flutter/material.dart';

class AppTheme {
  // Tema verimizi 'static final' olarak tanımlayalım ki
  // dışarıdan kolayca erişilebilsin.
  static final ThemeData lightTheme = ThemeData(
    // Ana renk olarak C-LENS projesine uygun bir renk seçebiliriz
    // Şimdilik maviyi kullanalım.
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    
    // Uygulama geneli text teması
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 14.0),
    ),

    // Uygulama geneli buton teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );

  // Buraya bir de darkTheme (karanlık tema) ekleyebiliriz
  // static final ThemeData darkTheme = ThemeData(...);
}