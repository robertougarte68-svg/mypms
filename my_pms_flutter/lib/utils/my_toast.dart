import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class MyToast {
  static void success(String message) {
    _show(message: message, icon: Icons.check_circle, color: Colors.green);
  }

  static void error(String message) {
    _show(message: message, icon: Icons.error, color: Colors.red);
  }

  static void info(String message) {
    _show(message: message, icon: Icons.info, color: Colors.blue);
  }

  static void _show({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    BotToast.showCustomText(
      duration: const Duration(seconds: 3),
      toastBuilder: (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Colors.black26,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
