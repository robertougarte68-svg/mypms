import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/providers/user_provider.dart';
import 'package:my_pms/utils/permission_gate.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final regProv = context.watch<UserProvider>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow,
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Crear Cuenta",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Form(
                    key: regProv.formKey,
                    child: Column(
                      children: [
                        buildField(
                          context: context,
                          hint: "Nombre de usuario",
                          icon: Icons.account_circle,
                          errorText: regProv.errUser,
                          onSaved: (value) => regProv.nwUser.user = value,
                          validator: (value) {
                            regProv.nwUser.user = value;

                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        buildField(
                          context: context,
                          hint: "Correo Electronico",
                          icon: Icons.email,
                          errorText: regProv.errEmail,
                          onSaved: (value) => regProv.nwUser.email = value,
                          validator: (value) {
                            regProv.nwUser.email = value;

                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }

                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Correo inválido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        buildField(
                          context: context,
                          hint: "Contrasena",
                          icon: Icons.password,
                          obscureText: true,
                          errorText: regProv.errPass,
                          onSaved: (value) => regProv.nwUser.pass = value,
                          validator: (value) {
                            regProv.nwUser.pass = value;

                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }

                            if (value.length < 8) {
                              return "Contrasena corta";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        buildField(
                          context: context,
                          hint: "Confirmar contrasena",
                          icon: Icons.password,
                          obscureText: true,
                          errorText: regProv.errPass,
                          onSaved: (value) => regProv.nwUser.pass2 = value,
                          validator: (value) {
                            regProv.nwUser.pass2 = value;

                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }

                            if (value.length < 8) {
                              return "Contrasena corta";
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                      ),
                      onPressed: () async {
                        if (regProv.formKey.currentState!.validate()) {
                          if (await regProv.sendUser()) {
                            regProv.formKey.currentState!.reset();

                            if (context.mounted) {
                              mensajeRapido("Registro exitoso", context);

                              GoRouter.of(context).go('/login');
                            }

                            return;
                          }

                          if (context.mounted) {
                            if (regProv.errhttp is SocketException) {
                              mensajeRapido(
                                "No se pudo conectar al servidor",
                                context,
                              );
                            } else {
                              mensajeRapido("Error desconocido", context);
                            }
                          }
                        }
                      },
                      child: Text(
                        "Registrarse",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () {
                      GoRouter.of(context).go('/login');
                    },
                    child: Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField({
    required BuildContext context,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    String? errorText,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      onSaved: onSaved,
      validator: validator,
      obscureText: obscureText,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        errorText: errorText,
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void mensajeRapido(String mssg, BuildContext contx) {
    ScaffoldMessenger.of(contx).showSnackBar(
      SnackBar(content: Text(mssg), duration: const Duration(seconds: 2)),
    );
  }
}
