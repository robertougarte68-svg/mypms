import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/data/device.dart';
import 'package:my_pms/data/room.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/providers/socket_provider.dart';
import 'package:my_pms/utils/my_snackbar.dart';
import 'package:my_pms/utils/my_toast.dart';
import 'package:provider/provider.dart';

class DeviceSection extends StatefulWidget {
  final Room room;
  final RoomProvider roomProv;

  const DeviceSection({super.key, required this.room, required this.roomProv});

  @override
  State<DeviceSection> createState() => _DeviceSectionState();
}

class _DeviceSectionState extends State<DeviceSection> {
  late SocketProvider socketProv;
  // RoomProvider roomProv = widget.roomProv;

  bool showDevices = false;
  bool pairing = false;

  String? selectedDevice;
  String? pairedDevice;
  bool changes = false;

  @override
  void initState() {
    super.initState();

    socketProv = context.read<SocketProvider>();
  }

  @override
  void dispose() {
    super.dispose();
    // socketProv.dispose();
  }

  Future<void> pairDevice(BuildContext context) async {
    if (selectedDevice == null) return;

    setState(() {
      pairing = true;
    });
    // PRIMERA OPCION
    socketProv.pairDevice(
      roomId: widget.room.id,
      roomN: widget.room.number,
      deviceId: selectedDevice!,
      state: widget.room.state,
    );
    widget.room.device = selectedDevice!;
    await Future.delayed(Duration(seconds: 2));
    if (socketProv.paired) {
      socketProv.paired = false;
      setState(() {
        pairedDevice = selectedDevice;
        pairing = false;
        showDevices = false;
      });
      MyToast.success('Emparejado correctamente');
    } else {
      MySnackbar.error(context, 'Algo salio mal, intente mas tarde');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ThemeData theme = Theme.of(context);

    pairedDevice = widget.room.device;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //TITULO Y BOTON CLOSE
        Row(
          children: [
            Expanded(child: Text("Dispositivo De Control Operativo:")),
            IconButton(
              onPressed: () {
                GoRouter.of(context).pop(changes);
              },
              icon: Icon(Icons.close),
            ),
          ],
        ),

        const SizedBox(height: 10),
        //DISP VINCULADO y DELETE
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              //DISPOSITIVOS
              Expanded(
                child: Text(pairedDevice ?? "Ningún dispositivo vinculado"),
              ),
              IconButton(
                onPressed: () async {
                  bool? confirmado = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Eliminar'),
                      content: Text(
                        '¿Seguro que deseas eliminar y desemparejar el dispositivo?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(false),
                          child: Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => context.pop(true),
                          child: Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmado ?? false) {
                    widget.room.device =
                        null; //esta modificacion permite la reconstruccion del widget
                    await widget.roomProv.patchRoomItem({
                      "device": null,
                    }, widget.room.id);

                    setState(() {});
                  }
                },
                icon: Icon(Icons.delete),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        //AGREGAR-CAMBIAR BUTTON
        OutlinedButton(
          onPressed: () {
            setState(() {
              showDevices = !showDevices;
            });
          },
          child: Text(
            showDevices == true
                ? 'Cancelar'
                : pairedDevice == null
                ? "Agregar dispositivo"
                : "Cambiar dispositivo",
          ),
        ),
        SizedBox(height: 30),
        //CAJA DE DISPOSITIVOS DISPONIBLES
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: showDevices
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ValueListenableBuilder<List<Device>>(
                valueListenable: socketProv.availableDevices,
                builder: (_, devices, __) {
                  if (devices.isEmpty) {
                    return const Center(
                      child: Text("Buscando dispositivos..."),
                    );
                  }

                  return Column(
                    children: [
                      //TITLE
                      Text('Dispositivos disponibles:'),

                      // DISPOSITIVOS DISPONIBLES
                      Expanded(
                        child: ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (_, index) {
                            final device = devices[index];

                            final selected = selectedDevice == device.id;

                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              selected: selected,
                              title: Text(device.id),
                              subtitle: Text(
                                device.online ? "ONLINE" : "OFFLINE",
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check)
                                  : null,
                              onTap: () {
                                setState(() {
                                  selectedDevice = device.id;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      FilledButton(
                        onPressed: pairing
                            ? null
                            : () async {
                                await pairDevice(context);
                                changes = true;
                              },
                        child: pairing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(),
                              )
                            : const Text("Emparejar dispositivo"),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
