import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_pms/data/global_var.dart';
import 'package:my_pms/data/client.dart';

class Estancia {
  final List<Client> clients;
  final int room;
  final String mode;
  final double tarifa;
  final String pay_method;
  final DateTime date_in;
  final DateTime? date_out;

  Estancia({
    required this.clients,
    required this.room,
    required this.mode,
    required this.tarifa,
    required this.pay_method,
    required this.date_in,
    required this.date_out,
  });
}

class ClientProvider extends ChangeNotifier {
  String ip = GlobalVar.ip;
  List<Estancia> _clients = [];
  List<dynamic> similars = [];
  // Estancia specificClient = Estancia(id: 0, nameSr: "", edad: 0, ci: 0);
  bool _loading = false;

  List<Estancia> get clients => _clients;
  bool get loading => _loading;

  //DEVUELVE LAS ESTADISTICAS DE UN CLIENTE ID
  Future<dynamic> getStatics(int id) async {
    final response = await http.get(
      Uri.parse('http://$ip:3000/api/clientes/statics/$id'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  //Solicita similares a la DB
  //TODO que devuelva la lista de clientes de una (strigs)
  Future<List<String>> searchSimilars(String similar) async {
    final response = await http.get(
      Uri.parse('http://$ip:3000/api/clientes/search?query=$similar'),
    );

    if (response.statusCode == 200) {
      similars = json.decode(response.body);
      print('${similars}');
      return similars
          .map((e) => e["name"])
          .where((e) => e != null)
          .cast<String>()
          .toList();
    } else {
      print(response.statusCode);
      print(json.decode(response.body));
      throw response.statusCode;
    }
  }

  //Solicita CLIENTE ESPECIFICO a la DB
  //TODO cambiar parametro por nombre nomas y que retorne un cliente
  Future<Map<String, dynamic>> getClient(String name) async {
    final response = await http.get(
      Uri.parse('http://${ip}:3000/api/clientes/$name'),
    );

    if (response.statusCode == 200) {
      // specificClient = Client.fromJson(json.decode(response.body)[0]);
      return jsonDecode(response.body).first as Map<String, dynamic>;
    } else {
      throw response.statusCode;
    }
  }

  //Solicita CLIENTE ESPECIFICO a la DB
  Future<Map<String, dynamic>> getClientByCi(String ci) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:3000/api/clientes/?ci=$ci'))
          .timeout(Duration(seconds: 3));

      if (response.statusCode < 300) {
        return jsonDecode(response.body).first;
      } else if (response.statusCode == 404) {
        return {};
      } else {
        print(jsonDecode(response.body));
        throw response.statusCode;
      }
    } on TimeoutException {
      print("demasiada demora en getClientByCi");
      return {};
    }
  }

  Future<int> writeClient(Map<String, dynamic> client) async {
    final response = await http.post(
      Uri.parse('http://${ip}:3000/api/clientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(client),
    );

    if (response.statusCode < 300) {
      return jsonDecode(response.body)['id'];
    } else {
      print(response.body);
      throw response.statusCode;
    }
  }
}
