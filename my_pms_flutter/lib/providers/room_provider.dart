import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_pms/data/global_var.dart';
import 'package:my_pms/data/room.dart';
import 'package:my_pms/providers/auth_provider.dart';

class RoomProvider extends ChangeNotifier {
  String ip = GlobalVar.ip;
  List<Room> _rooms = [];
  String? _errMsg;
  bool _loading = false;
  ErrStates _errState = ErrStates.sucess;
  List<Room> get rooms => _rooms;
  bool get loading => _loading;
  String? get errMsg => _errMsg;
  ErrStates get errState => _errState;

  void refresh() {
    notifyListeners();
  }

  Future<Room?> getRoom(int n, int hotel_id) async {
    final response = await http.get(
      Uri.parse('http://$ip:3000/api/rooms/$hotel_id/$n'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode < 300) {
      print(response.body);
      return Room.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) {
      return null;
    } else {
      print(jsonDecode(response.body));
      throw response.statusCode;
    }
  }

  //este metodo solicita todas las habitaciones de la db.
  Future<void> fetchRooms(int? hotel_id) async {
    if (_errState == ErrStates.loading) return;
    _errState = ErrStates.loading;
    print("empezando fetchRooms en provider");
    try {
      final url = Uri.parse('http://$ip:3000/api/rooms/$hotel_id');
      // print(url);
      // print(hotel_id);
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        List jsonData = json.decode(response.body);
        _rooms = jsonData.map((e) => Room.fromJson(e)).toList();
        _errState = ErrStates.sucess;
        _errMsg = null;
      } else {
        _errState = ErrStates.error;
        _errMsg = "Error ${response.statusCode}: ${response.body}";
        print(
          "respuesta fuera de 200 en fetchRooms en provider ${response.statusCode}",
        );
        // throw response.statusCode;
      }
    } on TimeoutException catch (e) {
      _errState = ErrStates.error;
      _errMsg = "No se pudo conectar con el servidor, tiempo excedido.";
      print("Tiempo exedido en fetchRooms: $e");

      // throw e;
    } on http.ClientException catch (e) {
      _errState = ErrStates.error;
      _errMsg = "Error de cliente al intentar conectar con el servidor.";
      print("ClientException en fetchRooms: $e");

      // throw e;
    } catch (e) {
      _errMsg = "Error inesperado al cargar las habitaciones.";
      _errState = ErrStates.error;
      print("Error inesperadoen fetchRooms: $e");
      throw e;
    }

    _loading = false;
    notifyListeners();
  }

  //This metod add a new room to the DB
  Future<void> postRoom(Map<String, dynamic> room) async {
    /*
   formato de room
   {
    "cat":"varchar",
    "number": int,
    "features": "varchar",
    "price": int,
    "hotel_id": int,
   }
    */
    final response = await http.post(
      Uri.parse('http://$ip:3000/api/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(room),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("se ha ejecutado postRoom");
    } else {
      throw response.statusCode;
    }
    // _loading = false;
  }

  //This metod change the state of the room
  Future<void> patchRoom(Room room, int id) async {
    final response = await http.patch(
      Uri.parse('http://$ip:3000/api/rooms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(room),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      notifyListeners();
      print(("notifylisteners ejecutado"));
    } else {
      throw response.statusCode;
    }
  }

  //This metod change the state of the room
  Future<void> patchRoomItem(Map<String, dynamic> item, int id_room) async {
    final response = await http.patch(
      Uri.parse('http://$ip:3000/api/rooms/item/$id_room'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      notifyListeners();
      print(("notifylisteners ejecutado"));
    } else {
      throw response.statusCode;
    }
  }

  //This metod deletes a room in the db
  Future<void> deleteRoom(int id) async {
    final response = await http.delete(
      Uri.parse('http://$ip:3000/api/rooms/$id'),
    );
    if (199 < response.statusCode && response.statusCode < 300) {
      // notifyListeners();
    } else {
      throw response.statusCode;
    }
  }

  Future<int?> getId(int num, int idHotel) async {
    final response = await http.get(
      Uri.parse('http://$ip:3000/api/rooms/idroom/?num=$num&idHotel=$idHotel'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode < 300) {
      return jsonDecode(response.body)['id'];
    }
    if (response.statusCode == 404) {
      return null;
    } else {
      print(jsonDecode(response.body));
      throw response.statusCode;
    }
  }

  // ///This metod add a new hotel and return hotel's id.
  // ///Formato de room:
  // ///{
  // /// "hotelname":"varchar",
  // /// "owner": "varchar",
  // /// "rooms": int,
  // ///"code": "varchar"
  // ///}
  // Future<int> postHotel(Map<String, dynamic> hotel) async {
  //   final response = await http.post(
  //     Uri.parse('http://$ip:3000/api/hotels'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(hotel),
  //   );

  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     final data = jsonDecode(response.body);
  //     if (data['id'] == null) {
  //       throw Exception('Respuesta sin id');
  //     }
  //     return data['id'];
  //   } else {
  //     throw Exception('Error ${response.statusCode}: ${response.body}');
  //   }
  // }

  // /// Valida el codigo de hotel. Si existe retorna el id del hotel
  // Future<int?> valitCode(String code) async {
  //   final myUrl = Uri.parse('http://$ip:3000/database/rooms/hotel/$code');
  //   Map<String, String> myHead = {
  //     // "Content-Type": "application/json",
  //     "Accept": "application/json",
  //   };

  //   final response = await http.get(myUrl, headers: myHead);
  //   if (response.statusCode < 300) {
  //     final id = jsonDecode(response.body)["id"];
  //     if (id is int) {
  //       return id;
  //     }
  //   }
  //   print(jsonDecode(response.body));
  //   print(response.statusCode);
  //   return null;
  // }

  // Future<int> writeStay(Map<String, dynamic> stayFields) async {
  //   final url = Uri.parse('http://$ip:3000/database/rooms/hotel/stay');
  //   Map<String, String> myHead = {'Content-Type': 'application/json'};
  //   final response = await http.post(
  //     url,
  //     headers: myHead,
  //     body: jsonEncode(stayFields),
  //   );
  //   if (response.statusCode < 300) {
  //     return jsonDecode(response.body)['id'];
  //   } else {
  //     print(response.body);
  //     throw response.statusCode;
  //   }
  // }
}
