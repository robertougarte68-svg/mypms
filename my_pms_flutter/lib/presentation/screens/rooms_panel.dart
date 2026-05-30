import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/presentation/screens/device_section.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_pms/data/room.dart';

class RoomsPanel extends StatefulWidget {
  const RoomsPanel({super.key});

  @override
  State<RoomsPanel> createState() => _RoomsPanelState();
}

class _RoomsPanelState extends State<RoomsPanel> {
  //TODO obtener de db
  late RoomProvider roomProv;
  late AuthProvider authProv;
  // late RoomProvider roomProv;
  List<Room> _rooms = [];

  @override
  void initState() {
    super.initState();
    roomProv = context.read<RoomProvider>();
    authProv = context.read<AuthProvider>();

    _loadRooms();
  }

  Future<void> _loadRooms() async {
    await roomProv.fetchRooms(authProv.hotel_id);

    if (!mounted) return;

    setState(() {
      _rooms = List.from(roomProv.rooms);
    });
  }

  void openRoomModal({Room? room}) async {
    final result = await showModalBottomSheet<Room>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      // shape: const RoundedRectangleBorder(
      //   borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      // ),
      builder: (_) => RoomFormModal(room: room),
    );

    if (result == null) return;

    setState(() {
      if (room == null) {
        _rooms!.add(result);
      } else {
        final index = _rooms!.indexWhere((r) => r.id == room.id);
        _rooms![index] = result;
      }
    });
  }

  void deleteRoom(Room room) async {
    await roomProv.deleteRoom(room.id);

    if (!mounted) return;

    setState(() {
      _rooms.removeWhere((r) => r.id == room.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).pop();
          },
        ),
        title: const Text("Habitaciones"),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoomModal(),
        icon: const Icon(Icons.add),
        label: const Text("Nueva"),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, index) {
          final room = _rooms![index];

          return RoomCard(
            room: room,
            onEdit: () => openRoomModal(room: room), //para el icon edit
            onDelete: () => deleteRoom(room), //para el icon delete
            onUpdate: () => _loadRooms(),
          );
        },
      ),
    );
  }
}

//CARDS QUE TIENEN TODA LA INFORMACION
class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const RoomCard({
    super.key,
    required this.room,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdate,
  });
  //MODAL PARA EMPAREJAR DEVICE
  void _openModalDevice(BuildContext context, RoomProvider roomProv) async {
    bool? changes = await showModalBottomSheet<bool>(
      isDismissible: false,
      context: context,
      barrierColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: DeviceSection(room: room, roomProv: roomProv),
      ),
    );
    if (changes ?? false) {
      onUpdate();
    }
  }

  Widget infoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    RoomProvider roomProv = context
        .watch<RoomProvider>(); //se podra actualizar RoomCard

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// NUMERO
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  room.number.toString(),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),

            const SizedBox(width: 20),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.cat,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),

                      Chip(label: Text(room.state)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  /// GRID INFO
                  Wrap(
                    spacing: 24,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: 180,
                        child: infoItem(
                          context,
                          icon: Icons.payments_outlined,
                          label: "Price Bs.${room.price}",
                        ),
                      ),

                      SizedBox(
                        width: 180,
                        child: infoItem(
                          context,
                          icon: Icons.bed,
                          label: 'Slots ${room.slots}',
                        ),
                      ),

                      infoItem(
                        context,
                        icon: Icons.description_outlined,
                        label: 'Features: ${room.features!}',
                      ),

                      // SizedBox(
                      //   width: 180,
                      //   child: infoItem(
                      //     context,
                      //     icon: Icons.devices,
                      //     label: '${room.device}',
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// ACTIONS
            Column(
              children: [
                IconButton(
                  color: theme.colorScheme.onSurface,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  color: theme.colorScheme.onSurface,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.memory, size: 30),
                  label: Text(room.device ?? 'Sin Dispositivo'),
                  onPressed: () {
                    _openModalDevice(context, roomProv);
                  },
                  style: OutlinedButton.styleFrom(
                    // foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//WIDGET PARA CREAR NUEVA HABITACION O EDITARLA
class RoomFormModal extends StatefulWidget {
  final Room? room;

  const RoomFormModal({super.key, this.room});

  @override
  State<RoomFormModal> createState() => _RoomFormModalState();
}

class _RoomFormModalState extends State<RoomFormModal> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController numberController;
  late TextEditingController catController;
  late TextEditingController priceController;
  late TextEditingController featuresController;
  late TextEditingController slotsController;
  late TextEditingController deviceController;

  @override
  void initState() {
    super.initState();

    numberController = TextEditingController(
      text: widget.room?.number.toString() ?? '',
    );

    catController = TextEditingController(text: widget.room?.cat ?? '');

    priceController = TextEditingController(
      text: widget.room?.price.toString() ?? '',
    );

    featuresController = TextEditingController(
      text: widget.room?.features ?? '',
    );
    slotsController = TextEditingController(
      text: '${widget.room?.slots ?? ''}',
    );
    deviceController = TextEditingController(text: widget.room?.device ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.room != null;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? "Editar habitación" : "Nueva habitación",
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Número"),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return "Número inválido";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: catController,
                decoration: const InputDecoration(labelText: "Categoria"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Campo obligatorio";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Precio"),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return "Precio inválido";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: slotsController,
                decoration: const InputDecoration(labelText: "Capacidad"),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: featuresController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Características"),
              ),

              const SizedBox(height: 28),

              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final room = Room(
                    id:
                        widget.room?.id ??
                        DateTime.now().millisecondsSinceEpoch,
                    number: int.parse(numberController.text),
                    cat: catController.text,
                    slots: int.parse(slotsController.text),
                    price: double.parse(priceController.text),
                    features: featuresController.text,
                    state: widget.room?.state ?? "READY",
                  );

                  Navigator.pop(context, room);
                },
                child: Text(isEdit ? "Guardar cambios" : "Crear habitación"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
