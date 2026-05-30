import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_pms/data/global_var.dart';

class User {
  // String? name;
  String? user;
  String? email;
  String? pass;
  String? pass2;

  User();

  Map<String, dynamic> toJson() => {
    // "name": name,
    "user": user,
    "email": email,
    "password": pass,
  };
}

class UserProvider extends ChangeNotifier {
  Object? _errhttp;
  final nwUser = User();
  final _formKey = GlobalKey<FormState>();
  String? errUser;
  String? errEmail;
  String? errPass;
  String? ip = GlobalVar.ip;
  GlobalKey<FormState> get formKey => _formKey;
  Object? get errhttp => _errhttp;
  bool passValidation() {
    if (nwUser.pass != null && nwUser.pass == nwUser.pass2) {
      errPass = null;
      return true;
    } else {
      errPass = 'Contrasenas no coinciden';
      notifyListeners();
      return false;
    }
  }

  //registrar nuevo usuario
  Future<bool> sendUser() async {
    // ip = await obtenerIPLocal();
    // print(ip);

    if (ip != null) {
      final url = Uri.parse("http://$ip:3000/api/users/registerUser");
      final head = {"Content-Type": "application/json"};
      final bodi = jsonEncode(nwUser.toJson());
      try {
        final response = await http
            .post(url, headers: head, body: bodi)
            .timeout(Duration(seconds: 2));
        if (response.statusCode < 300) {
          errEmail = null;
          errUser = null;
          _errhttp = null;
          print("usuario registrado");
          print(jsonDecode(response.body));
          return true;
        }

        if (jsonDecode(response.body)['message'] == 'user') {
          errUser = 'usuario ya existente';
          errEmail = null;
        } else if (jsonDecode(response.body)['message'] == 'email') {
          errEmail = 'email ya existente';
          errUser = null;
        }
        print(jsonDecode(response.body));
        notifyListeners();
        // print(response);
      } on SocketException catch (e) {
        _errhttp = e;
        if (e.message.contains("Failed host lookup")) {
          print("Dominio no existe (DNS)");
        } else {
          print("Servidor no accesible");
        }
      } on http.ClientException catch (e) {
        _errhttp = e;
        print('error de cliente $e');
      } on TimeoutException catch (e) {
        _errhttp = e;

        print('Tiempo de espera agotado');
      } catch (e) {
        _errhttp = e;
        print('Error inesperado: $e');
      }
    } else {
      print("problema de ip, no se pudo obtenerla");
    }
    return false;
  }

  Future<bool> patchUser(Map<String, dynamic> parche, String? username) async {
    final url = Uri.parse('http://$ip:3000/api/users/$username');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer TU_TOKEN',
      },
      body: jsonEncode(parche),
    );

    if (response.statusCode < 300) {
      print('usuario $username parchado con $parche');
      return true;
    } else {
      print(
        'error de servidor. Status Code: ${response.statusCode}. Body: ${response.body}',
      );
      return false;
    }
  }

  Future<String?> getUser(int userId) async {
    try {
      final url = Uri.parse('http://$ip:3000/api/users/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['user'] as String?;
      } else {
        print(
          'Error de servidor. Status Code: ${response.statusCode}. Body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error inesperado: $e');
      return null;
    }
  }
}
