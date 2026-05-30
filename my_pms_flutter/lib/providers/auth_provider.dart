import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_pms/data/global_var.dart';
import 'package:my_pms/data/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _loggedIn = true; //TODO: cambiar a false para produccion

  //TODO comentar este usuario para produccion
  User? logUser = User(
    id: 16,
    email: 'junior2@gmail.com',
    user: 'junior2',
    rol: 'propietario',
    hotelId: 14,
    permisos: [
      'ver_reservas',
      'gestionar_reservas',
      'ver_habitaciones',
      'gestionar_habitaciones',
      'ver_reportes',
      'gestionar_reportes',
      'ver_finanzas',
      'gestionar_finanzas',
    ],
    token: '',
  );
  //TODO descomentar para procuccion
  // User? logUser;

  String? _errEmail;
  String? _errPass;

  final _emailControl = TextEditingController();
  final _passControl = TextEditingController();

  int? get hotel_id => logUser?.hotelId;
  String? get username => logUser?.user;
  String? get userEmail => logUser?.email;
  int? get userId => logUser?.id;

  TextEditingController get emailControl => _emailControl;
  TextEditingController get passControl => _passControl;

  String ip = GlobalVar.ip;

  String? get errEmail => _errEmail;
  String? get errPass => _errPass;

  String? get userRol => logUser?.rol;
  set userRol(String rol) => logUser?.rol = rol;
  set hotel_id(int? idHotel) => {logUser?.hotelId = idHotel};

  bool get isLogged => _loggedIn;

  bool can(String permiso) {
    return logUser?.permisos.contains(permiso) ?? false;
  }

  bool loggedIn(String rol) {
    if (_loggedIn && logUser?.rol == rol) return true;
    return false;
  }

  Future<String> login(String email, String password) async {
    final url = Uri.parse("http://$ip:3000/api/users/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim(), "password": password.trim()}),
      );

      final data = jsonDecode(response.body);

      // LOGIN EXITOSO
      if (response.statusCode == 200) {
        logUser = User.fromJson(data);

        // GUARDAR LOCAL
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', logUser!.token);

        // await prefs.setString('userData', jsonEncode(user.toJson()));

        _loggedIn = true;

        _errEmail = null;
        _errPass = null;

        notifyListeners();
        print(logUser);
        return 'exito';
      }

      // USUARIO NO EXISTE
      if (response.statusCode == 404) {
        _errEmail = 'usuario no existente';
        _errPass = null;

        notifyListeners();

        return 'usuario no existente';
      }

      // PASSWORD INCORRECTA
      if (response.statusCode == 401) {
        _errPass = 'contrasena incorrecta';
        _errEmail = null;

        notifyListeners();

        return 'contrasena incorrecta';
      }

      // ERROR BACKEND
      return data["message"] ?? 'error servidor';
    }
    // // ERROR HTTP
    // on http.ClientException catch (e) {
    //   print('HTTP ERROR: $e');
    //   return 'problema de conexion';
    // }
    // // TIMEOUT
    // on TimeoutException {
    //   return 'servidor no responde';
    // }
    // // JSON INVALIDO
    // on FormatException {
    //   return 'respuesta invalida del servidor';
    // }
    // ERROR GENERAL
    catch (e) {
      print('ERROR LOGIN: $e');
      return 'error inesperado';
    }
  }

  // void logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('token');
  //   _loggedIn = false;
  //   _userEmail = null;
  //   _userRol = null;
  //   _username = null;
  //   notifyListeners();
  // }
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _loggedIn = false;
    logUser = null;
    notifyListeners();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
