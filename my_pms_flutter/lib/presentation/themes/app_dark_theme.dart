import 'package:flutter/material.dart';

class AppDarkTheme {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _background = Color(0xFF0F0F0F);
  static const Color _surface = Color(0xFF1C1C1C);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: _background,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: _gold,
        onPrimary: Colors.black,
        secondary: _gold,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        surface: _surface,
        onSurface: Colors.white,
        surfaceContainer: Color(0xFF1C1C1C),
        surfaceContainerHigh: Color.fromARGB(255, 40, 40, 40),
        surfaceContainerHighest: Color.fromARGB(255, 50, 50, 50),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _gold),
        titleTextStyle: TextStyle(
          color: _gold,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: _surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _gold, width: 2),
        ),
        labelStyle: const TextStyle(color: _gold),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
      ),
    );
  }
}
