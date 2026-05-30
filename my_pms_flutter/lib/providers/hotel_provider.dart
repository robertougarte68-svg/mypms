import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_pms/data/global_var.dart';
import 'package:my_pms/data/reservation.dart';

class HotelProvider extends ChangeNotifier {
  String ip = GlobalVar.ip;
  Map<String, dynamic>? _stays;

  Map<String, dynamic>? get stays => _stays;
  // stays:
  // {
  //   "stays": [{},{},{}...],
  //   "clients": [{},{},{}...],
  // }

  //MODIFICAR RESERVA
  Future<void> modificarReserva(
    String cod,
    String estado,
    String observaciones,
  ) async {
    final response = await http.put(
      Uri.parse('http://$ip:3000/api/hotel/reservas/$cod/estado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado, 'observaciones': observaciones}),
    );

    if (response.statusCode == 200) {
      print('Reserva $cod modificada a estado $estado');
    } else {
      print(response.body);
      throw response.statusCode;
    }
  }

  Future<List<Reservation>?> getReservas(
    int status, {
    int? n,
    DateTime? fecha_inicio,
    DateTime? fecha_fin,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://$ip:3000/api/hotel/reservas?estado=$status&n=$n&fecha_inicio=${fecha_inicio?.toIso8601String()}&fecha_fin=${fecha_fin?.toIso8601String()} ',
        ),
      );
      if (response.statusCode == 200) {
        List<Reservation> reservasBS = [];
        for (final reserva in jsonDecode(response.body)) {
          reservasBS.add(Reservation.fromJson(reserva));
        }
        return reservasBS;
      } else {
        print('ERROR ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  ///This metod add a new hotel and return hotel's id.
  ///Formato de room:
  ///{
  /// "hotelname":"varchar",
  /// "owner": "varchar",
  /// "rooms": int,
  ///"code": "varchar"
  ///}
  Future<int> postHotel(Map<String, dynamic> hotel) async {
    final response = await http.post(
      Uri.parse('http://$ip:3000/api/hotel/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(hotel),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['id'] == null) {
        throw Exception('Respuesta sin id');
      }
      return data['id'];
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Valida el codigo de hotel. Si existe retorna el id del hotel
  Future<int?> valitCode(String code) async {
    final myUrl = Uri.parse('http://$ip:3000/api/hotel/unirse/$code');
    Map<String, String> myHead = {
      // "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final response = await http.get(myUrl, headers: myHead);
    if (response.statusCode < 300) {
      final id = jsonDecode(response.body)["id"];
      if (id is int) {
        return id;
      }
    }
    print(jsonDecode(response.body));
    print(response.statusCode);
    return null;
  }

  Future<int> writeStay(Map<String, dynamic> stayFields) async {
    final url = Uri.parse('http://$ip:3000/api/hotel/stay');
    Map<String, String> myHead = {'Content-Type': 'application/json'};
    final response = await http.post(
      url,
      headers: myHead,
      body: jsonEncode(stayFields),
    );
    if (response.statusCode < 300) {
      return jsonDecode(response.body)['id'];
    } else {
      print(response.body);
      throw response.statusCode;
    }
  }

  Future<bool> writeCiS(int idSty, List<int> idClients) async {
    const head = {'Content-Type': 'application/json'};
    final cuerpo = {'id_stay': idSty, 'id_clients': idClients};
    final response = await http.post(
      Uri.parse('http://$ip:3000/api/clientes/writeCiS'),
      headers: head,
      body: jsonEncode(cuerpo),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print(response.body);
      return false;
    }
  }

  Future<void> getStays(int n, int id_hotel) async {
    final response = await http.get(
      Uri.parse(
        'http://$ip:3000/api/clientes/fullstays?n=$n&id_hotel=$id_hotel',
      ),
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      _stays = jsonDecode(response.body);
      notifyListeners();
    } else {
      throw response.statusCode;
    }
  }

  Future<void> getStaysByRange(
    DateTime start,
    DateTime end,
    int id_hotel,
  ) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final response = await http.get(
      Uri.parse(
        'http://$ip:3000/api/hotel/fullstaysByRange'
        '?start=$startStr&end=$endStr&id_hotel=$id_hotel',
      ),
    );

    if (response.statusCode == 200) {
      _stays = jsonDecode(response.body);
      notifyListeners();
    } else {
      throw response.statusCode;
    }
  }

  Future<void> checkoutStay(int id_stay) async {
    final response = await http.patch(
      Uri.parse('http://$ip:3000/api/hotel/checkout?id_stay=$id_stay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': 'aplicar fecha actual'}),
    );

    if (response.statusCode == 200) {
      // Actualizar la lista de estancias después del checkout
      notifyListeners();
    } else {
      print(response.body);
      throw response.statusCode;
    }
  }

  Future<List<Map<String, dynamic>>> getCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:3000/api/hotel/categorias'),
      );
      if (response.statusCode == 200) {
        // print(response.body);
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<String?> getCategory(int catId) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:3000/api/hotel/categoria/$catId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['nombre'] as String;
      } else {
        print(
          'Error de servidor. Status Code: ${response.statusCode}. Body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error al obtener la categoría: $e');
      return null;
    }
  }

  Future<bool> addCashFlow(Map<String, dynamic> cashfields) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ip:3000/api/hotel/cashflow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cashfields),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        print(response.body);
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getCashFlow(String filter) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:3000/api/hotel/cashflow?filter=$filter'),
      );
      if (response.statusCode == 200) {
        // print(response.body);
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print(response.body);
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<double> getIngresos(
    int? dias,
    DateTime? date1,
    DateTime? date2,
  ) async {
    try {
      final uri = Uri.http('$ip:3000', '/api/hotel/ingresos', {
        if (dias != null) 'dias': dias.toString(),

        if (date1 != null) 'date1': date1.toIso8601String().split('T')[0],

        if (date2 != null) 'date2': date2.toIso8601String().split('T')[0],
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        return (res["ingresos"]["total"] as num).toDouble();
      } else {
        print(response.body);
        return 0;
      }
    } catch (e) {
      print(e);
      return 0;
    }
  }

  Future<double> getEgresos(int? dias, DateTime? date1, DateTime? date2) async {
    try {
      final uri = Uri.http('$ip:3000', '/api/hotel/egresos', {
        if (dias != null) 'dias': dias.toString(),

        if (date1 != null) 'date1': date1.toIso8601String().split('T')[0],

        if (date2 != null) 'date2': date2.toIso8601String().split('T')[0],
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        return double.parse(res["egresos"]["total"]);
      } else {
        print(response.body);
        return 0;
      }
    } catch (e) {
      print(e);
      return 0;
    }
  }

  Future<double> getSaldo(int? dias, DateTime? date1, DateTime? date2) async {
    try {
      final uri = Uri.http('$ip:3000', '/api/hotel/saldo', {
        if (dias != null) 'dias': dias.toString(),

        if (date1 != null) 'date1': date1.toIso8601String().split('T')[0],

        if (date2 != null) 'date2': date2.toIso8601String().split('T')[0],
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        return (res["saldo"] as num).toDouble();
      } else {
        print(response.body);
        return 0;
      }
    } catch (e) {
      print(e);
      return 0;
    }
  }

  // // TODO INCOMPLETO
  // Future<double> ingsFrmStys(int hotel_id, String filtro) async {
  //   final response = await http.get(
  //     Uri.parse(
  //       'http://$ip:3000/api/hotel/estancias/ingresos?filtro=$filtro&id_hotel=$hotel_id',
  //     ),
  //   );
  //   if (response.statusCode == 200) {
  //     return double.parse(jsonDecode(response.body)[0]['total']);
  //   } else {
  //     throw response.statusCode;
  //   }
  // }
}
