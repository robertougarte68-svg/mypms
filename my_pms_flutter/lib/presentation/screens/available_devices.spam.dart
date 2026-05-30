import 'package:flutter/material.dart';
import 'package:my_pms/providers/socket_provider.dart';
import 'package:provider/provider.dart';

class AvailableDevices extends StatefulWidget {
  const AvailableDevices({super.key});

  @override
  State<AvailableDevices> createState() => _AvailableDevicesState();
}

class _AvailableDevicesState extends State<AvailableDevices> {
  @override
  void initState() {
    super.initState();

    // Future.microtask(() {
    //   context.read<SocketProvider>().connect();
    // });
  }

  @override
  Widget build(BuildContext context) {
    final socketProv = context.read<SocketProvider>();

    return ValueListenableBuilder(
      valueListenable: socketProv.availableDevices,
      builder: (context, devices, _) {
        if (!socketProv.connected) {
          return const Center(child: Text('Desconectado'));
        }

        if (devices.isEmpty) {
          return const Center(child: Text('No hay dispositivos'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];

            return ListTile(
              leading: const Icon(Icons.devices),
              title: Text(device.id),
              subtitle: Text(device.online ? 'activo' : 'inactivo'),
              trailing: ElevatedButton(
                onPressed: () {
                  // socketProv.pairDevice(roomId: widget.room.id, roomN: device.id);
                },
                child: const Text('Emparejar'),
              ),
            );
          },
        );
      },
    );
  }
}
