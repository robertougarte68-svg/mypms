import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pms/data/device.dart';
import 'package:my_pms/data/global_var.dart';
import 'package:web_socket_channel/io.dart';

class SocketProvider extends ChangeNotifier {
  late IOWebSocketChannel channel;
  final ValueNotifier<List<Device>> availableDevices = ValueNotifier([]);
  bool paired = false;

  bool connected = false;
  Future<void> connect() async {
    try {
      channel = IOWebSocketChannel.connect('ws://${GlobalVar.ip}:3500');

      await channel.ready;

      connected = true;
      notifyListeners();
      print('CHANNEL CONECTED');
      //ESUCHANDO PERMANENTEMENTE
      channel.stream.listen(
        (data) {
          // print(data);
          final decoded = jsonDecode(data);
          final event = decoded['event'];
          final payload = decoded['data'];

          switch (event) {
            case "available_devices":
              availableDevices.value = (payload as Map<String, dynamic>).entries
                  .map((e) => Device.fromJson({"device_id": e.key, ...e.value}))
                  .toList();
              print('available devices: ');
              print(availableDevices.value);

              break;

            // case "confirm_pair_device":
            //   paired = decoded['paired'];

            //   notifyListeners();

            //   break;
          }
        },
        onDone: () {
          connected = false;
          // notifyListeners();
        },
        onError: (e) {
          connected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      connected = false;
      // notifyListeners();

      print(e);
    }
  }

  //mensaje para emparejar dispositivo
  void pairDevice({
    required int roomId,
    required int roomN,
    required String deviceId,
    required String state,
  }) {
    channel.sink.add(
      jsonEncode({
        "event": "pair_device",
        "data": {
          "room_id": roomId,
          "room_n": roomN,
          "device_id": deviceId,
          'state': state,
        },
      }),
    );
    paired = true;
    // notifyListeners();
  }

  void disconnect() {
    channel.sink.close();
  }

  // @override
  // void dispose() {
  //   disconnect();
  //   super.dispose();
  // }
}
