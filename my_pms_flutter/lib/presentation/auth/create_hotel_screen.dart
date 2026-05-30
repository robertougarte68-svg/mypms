import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/providers/user_provider.dart';
import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';

class CreateHotelScreen extends StatefulWidget {
  const CreateHotelScreen({super.key});

  @override
  State<CreateHotelScreen> createState() => _CreateHotelScreenState();
}

class _CreateHotelScreenState extends State<CreateHotelScreen> {
  late RoomProvider roomProv;
  late AuthProvider authProv;
  late UserProvider userProv;
  late HotelProvider hotelProv;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hotelNameCtrl = TextEditingController();
  final TextEditingController _roomNumberCtrl = TextEditingController();
  final TextEditingController _roomNameCtrl = TextEditingController();
  final TextEditingController _featuresCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  final List<Map<String, dynamic>> _rooms = [];
  final Map<String, dynamic> _hotel = {
    "hotelname": null,
    "owner": null,
    "rooms": null,
    "code": null,
  };

  void _addRoom() {
    //numero, nombre y precio obligatorios
    if (_roomNumberCtrl.text.isEmpty ||
        _roomNameCtrl.text.isEmpty ||
        _priceCtrl.text.isEmpty) {
      return;
    }

    setState(() {
      _rooms.add({
        "number": int.parse(_roomNumberCtrl.text),
        "name": _roomNameCtrl.text,
        "features": _featuresCtrl.text,
        "price": int.parse(_priceCtrl.text),
        "hotel_id": null,
      });
    });

    _roomNumberCtrl.clear();
    _roomNameCtrl.clear();
    _featuresCtrl.clear();
    _priceCtrl.clear();
  }

  void _removeRoom(int index) {
    setState(() {
      _rooms.removeAt(index);
    });
  }

  Future<void> _finishCreation() async {
    if (_hotelNameCtrl.text.isEmpty || _rooms.isEmpty) {
      return;
    }
    _hotel["hotelname"] = _hotelNameCtrl.text;
    _hotel["owner"] = authProv.username;
    _hotel["rooms"] = _rooms.length;
    _hotel["code"] = generarCodigo();
    //Envio de hotel
    try {
      print("hotel: $_hotel");
      int? idhotel = await hotelProv.postHotel(_hotel);

      print("$idhotel");
      bool updated = await userProv.patchUser({
        "hotel_id": idhotel,
        "rol": "propietario",
      }, authProv.username);
      if (!updated) {
        print('no se parcho el user con propietario');
        return;
      } else {
        print('usuario parchado con propietario');
      }

      for (var room in _rooms) {
        room['hotel_id'] = idhotel;
        await roomProv.postRoom(room);
      }
      authProv.userRol = "propietario";

      if (mounted) GoRouter.of(context).go('/homepage');
    } catch (e) {
      print(e);
    }
  }

  String generarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    roomProv = context.read<RoomProvider>();
    authProv = context.read<AuthProvider>();
    userProv = context.read<UserProvider>();
    hotelProv = context.read<HotelProvider>();
    print("CreateHotelScreen cargado");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); //importante definir el tema en el main

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Hotel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Información del Hotel", style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hotelNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre del Hotel",
                ),
              ),

              const SizedBox(height: 30),

              Text("Agregar Habitación", style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              //NUMERO
              TextFormField(
                controller: _roomNumberCtrl,
                decoration: const InputDecoration(labelText: "Número"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              //NOMBRE
              TextFormField(
                controller: _roomNameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              const SizedBox(height: 12),
              //FEATURES
              TextFormField(
                controller: _featuresCtrl,
                decoration: const InputDecoration(labelText: "Características"),
              ),
              const SizedBox(height: 12),
              //PRICE
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: "Precio por noche",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              //BUTTON AGREGAR HABITACION
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addRoom,
                  child: const Text("Agregar Habitación"),
                ),
              ),

              const SizedBox(height: 30),

              if (_rooms.isNotEmpty)
                Text("Habitaciones creadas", style: theme.textTheme.titleLarge),

              const SizedBox(height: 12),
              //LISTA DE HABS CREADAS (CARDS)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final room = _rooms[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        "Hab ${room["number"]} - ${room["name"]}",
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text("Bs. ${room["price"]}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeRoom(index),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
              //CANCELAR  & TERMINAR BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => GoRouter.of(context).pop(),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finishCreation,
                      child: const Text("Terminar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
