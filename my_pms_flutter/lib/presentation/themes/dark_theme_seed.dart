import 'package:flutter/material.dart';

final darkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFD4AF37), // dorado
  brightness: Brightness.dark,

  // opcional: hacer superficies más oscuras
  //   surface: const Color(0xFF121212),
  // ).copyWith(
  //   primary: const Color(0xFFD4AF37),
  //   secondary: const Color(0xFFE0C56E),

  //   surface: const Color(0xFF121212),
  //   surfaceContainerLow: const Color(0xFF1A1A1A),
  //   surfaceContainer: const Color(0xFF202020),
  //   surfaceContainerHigh: const Color(0xFF2A2A2A),

  //   onSurface: Colors.white,
  //   onPrimary: Colors.black,
);

final darkTheme = ThemeData(useMaterial3: true, colorScheme: darkScheme);
