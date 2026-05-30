import 'package:flutter/material.dart';

class MySnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    final theme = Theme.of(context);
    show(context, message: message, backgroundColor: theme.colorScheme.error);
  }

  static void success(BuildContext context, String message) {
    final theme = Theme.of(context);
    show(context, message: message, backgroundColor: theme.colorScheme.primary);
  }

  static void info(BuildContext context, String message) {
    final theme = Theme.of(context);
    show(context, message: message, backgroundColor: theme.colorScheme.outline);
  }
}
