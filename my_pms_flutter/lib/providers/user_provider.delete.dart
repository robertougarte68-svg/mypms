import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class User {
  final int id;
  final String name;
  final int edad;
  final int ci;

  User({
    required this.id,
    required this.name,
    required this.edad,
    required this.ci,
  });

  String get getName => name;
  int get getId => id;
  int get getEdad => edad;
  int get getCi => ci;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      edad: json['edad'] ?? 18,
      ci: json['ci'] ?? 9430657,
    );
  }
}

class UserProvider extends ChangeNotifier {
  String ip = "192.168.100.66";
  List<User> _users = [];
  List<dynamic> similars = [];
  User specificUser = User(id: 0, name: "", edad: 0, ci: 0);
  bool _loading = false;

  List<User> get users => _users;
  bool get loading => _loading;

  //Solicita USUARIO ESPECIFICO a la DB
  Future<void> getUserAuth(String user, String passw) async {
    final response = await http.get(
      Uri.parse('http://$ip:3000/database/users/$user/$passw'),
    );

    if (response.statusCode == 200) {
      specificUser = User.fromJson(json.decode(response.body));
    } else {
      throw response.statusCode;
    }
    notifyListeners();
  }

  Future<bool> patchUser(Map<String, dynamic> parche, String username) async {
    final url = Uri.parse('http://$ip:3000/users/$username');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer TU_TOKEN',
      },
      body: jsonEncode(parche),
    );

    if (response.statusCode < 300) {
      print("usuario $username parchado con $parche");
      return true;
    } else {
      print(
        "error de servidor. Status Code: ${response.statusCode}. Body: ${jsonDecode(response.body)}",
      );
      return false;
    }
  }
}
