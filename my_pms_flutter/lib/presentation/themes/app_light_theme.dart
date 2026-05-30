import 'package:flutter/material.dart';

class AppLightTheme {
  static const Color _gold = Color(0xFFB7932F);
  static const Color _background = Color.fromARGB(255, 232, 230, 226);
  static const Color _surface = Color.fromARGB(255, 255, 255, 255);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: _background,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _gold,
        onPrimary: Colors.white,
        secondary: _gold,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Color.fromARGB(255, 255, 255, 255),
        onSurface: Colors.black,
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
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
          color: Colors.black,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
