import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class GlobalProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  bool isDarkMode = true;

  void toggleTheme() {
    if (themeMode == ThemeMode.light) {
      themeMode = ThemeMode.dark;
      isDarkMode = true;
    } else {
      themeMode = ThemeMode.light;
      isDarkMode = false;
    }
    notifyListeners();
  }

  get darkMode => isDarkMode;
}
