import 'package:flutter/material.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:provider/provider.dart';

enum PermissionMode { all, any }

class PermissionGate extends StatelessWidget {
  final List<String> permisos;
  final PermissionMode mode;
  final Widget child;
  final String? messege;

  const PermissionGate({
    super.key,
    required this.permisos,
    required this.child,
    this.mode = PermissionMode.all,
    this.messege,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>();

    bool allowed = false;

    if (mode == PermissionMode.all) {
      allowed = permisos.every(session.can);
    } else {
      allowed = permisos.any(session.can);
    }

    if (!allowed) {
      if (messege != null) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(messege!),
        );
      }
      return const SizedBox.shrink();
    }

    return child;
  }
}
