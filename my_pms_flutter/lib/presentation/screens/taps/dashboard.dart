import 'package:my_pms/data/global_var.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/utils/permission_gate.dart';
import 'package:provider/provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/data/room.dart';

class MyDashboard extends StatefulWidget {
  const MyDashboard({super.key});

  @override
  State<MyDashboard> createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  late AuthProvider authProv;
  late RoomProvider provider;
  late HotelProvider hotelProv;
  late Timer _timer;
  double ingsDia = 0;
  double ingsMes = 0;
  double egsDia = 0;
  double egsMes = 0;

  var ocupacion = 0;
  var total = 0;

  @override
  void initState() {
    super.initState();
    authProv = context.read<AuthProvider>();
    provider = context.read<RoomProvider>();
    hotelProv = context.read<HotelProvider>();
    provider.fetchRooms(authProv.hotel_id);
    _loadFinances();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      provider.fetchRooms(authProv.hotel_id);
      List<Room> rooms = provider.rooms;
      ocupacion = 0;
      rooms.forEach((rm) {
        if (rm.state == "ocupado") {
          ocupacion++;
        }
        total = rooms.length;
      });
    });
  }

  @override
  void dispose() {
    print("dashpoard disposed");
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadFinances() async {
    DateTime tf = DateTime.now();
    DateTime t0 = DateTime(tf!.year, tf!.month, 1);
    ingsDia = await hotelProv.getIngresos(1, null, null);
    ingsMes = await hotelProv.getIngresos(null, t0, tf);
    egsDia = await hotelProv.getEgresos(1, null, null);
    egsMes = await hotelProv.getEgresos(null, t0, tf);
  }

  @override
  Widget build(BuildContext context) {
    final nsRoom = context.watch<RoomProvider>();
    final roomsData = nsRoom.rooms;

    final stateColors = {
      'libre': Colors.green,
      'ocupado': Colors.red,
      'mantenimiento': Colors.orange,
      'revision': Colors.yellow,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          // MOBILE
          return Column(
            children: [
              SizedBox(height: 50),
              indicadorOcupacion(5, 15),
              SizedBox(height: 50),
              indicadoresEconomicos(),
              SizedBox(height: 50),
              Expanded(child: gridHabitaciones(nsRoom, roomsData, stateColors)),
            ],
          );
        } else {
          // DESKTOP
          return Padding(
            padding: const EdgeInsets.all(50),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: gridHabitaciones(nsRoom, roomsData, stateColors),
                ),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        indicadorOcupacion(ocupacion, total),
                        SizedBox(height: 50),
                        PermissionGate(
                          permisos: ['ver_finanzas', 'ver_reportes'],
                          child: indicadoresEconomicos(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  } //build

  Color getColor(double p) {
    if (p < 0.5) return Colors.green;
    if (p < 0.8) return Colors.orange;
    return Colors.red;
  }

  Widget indicadorOcupacion(int ocupadas, int total) {
    double porcentaje = 0;
    if (total != 0) {
      porcentaje = ocupadas / total;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                color: getColor(porcentaje),
                value: porcentaje,
                strokeWidth: 10,
              ),
            ),
            Text(
              "${(porcentaje * 100).toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text("Ocupación"),
      ],
    );
  }

  Widget indicadoresEconomicos() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: kpiCard("Ingresos hoy", "${ingsDia}")),
              SizedBox(width: 10),
              Expanded(child: kpiCard("Ingresos mes", "${ingsMes}")),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: kpiCard("Egresos hoy", "${egsDia}")),
              SizedBox(width: 10),
              Expanded(child: kpiCard("Egresos Mes", "${egsMes}")),
            ],
          ),
        ],
      ),
    );
  }

  Widget kpiCard(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: Colors.black26),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget gridHabitaciones(
    RoomProvider nsRoom,
    List<Room> roomsData,
    Map<String, MaterialColor> stateColors,
  ) {
    return nsRoom.errState == ErrStates.loading
        ? const Center(child: CircularProgressIndicator())
        : nsRoom.errState == ErrStates.sucess
        ? GridView.count(
            // physics: const NeverScrollableScrollPhysics(),
            // shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,

            children: roomsData.map((room) {
              return ElevatedButton(
                onPressed: () => _showModalBottomSheet(context, nsRoom, room),
                style: ElevatedButton.styleFrom(
                  backgroundColor: stateColors[room.state] ?? Colors.grey,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.number.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(room.cat, style: const TextStyle(fontSize: 20)),
                      Text(room.state, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        : Center(
            child: Text(
              nsRoom.errMsg ?? "Error desconocido",
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
          );
  }

  void _showModalBottomSheet(
    BuildContext context,
    RoomProvider nsRoom,
    Room room,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => PermissionGate(
        messege: 'No puede gestionar las habitaciones',
        permisos: ['gestionar_habitaciones'],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStateTile(context, nsRoom, room, 'ocupado', Colors.red),
            _buildStateTile(context, nsRoom, room, 'libre', Colors.green),
            _buildStateTile(context, nsRoom, room, 'revision', Colors.yellow),
            _buildStateTile(
              context,
              nsRoom,
              room,
              'mantenimiento',
              Colors.orange,
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('Eliminar'),
              onTap: () async {
                await nsRoom.deleteRoom(room.id);
                await nsRoom.fetchRooms(authProv.hotel_id);
                if (context.mounted) {
                  context.pop();
                } else {
                  print("fallo de montado en ModalBottonSheet");
                  return;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildStateTile(
    BuildContext context,
    RoomProvider nsRoom,
    Room room,
    String newState,
    Color color,
  ) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(newState[0].toUpperCase() + newState.substring(1)),
      onTap: () async {
        await nsRoom.patchRoomItem({'state': newState}, room.id);
        await nsRoom.fetchRooms(authProv.hotel_id);
        if (context.mounted) {
          context.pop();
        } else {
          print("fallo de montado en ModalBottonSheet");
          return;
        }
      },
    );
  }
}
