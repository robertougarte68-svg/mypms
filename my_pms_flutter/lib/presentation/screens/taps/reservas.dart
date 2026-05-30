import 'package:my_pms/data/global_var.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/utils/my_snackbar.dart';
import 'package:my_pms/utils/permission_gate.dart';
import 'package:provider/provider.dart';
import 'package:my_pms/data/reservation.dart';

class Reservas extends StatefulWidget {
  const Reservas({super.key});

  @override
  State<Reservas> createState() => _ReservasState();
}

class _ReservasState extends State<Reservas> {
  String sortMode = "estado"; // estado | fecha
  DateTimeRange? range;

  List<Reservation> reservations = [];
  @override
  void initState() {
    super.initState();
    getReservations();
  }

  Future<void> getReservations() async {
    final hotelProv = context.read<HotelProvider>();
    final res = await hotelProv.getReservas(1);
    setState(() => reservations = res ?? []);
  }

  @override
  Widget build(BuildContext context) {
    // final hotelProv = context.read<HotelProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actionsIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: const Text("Reservas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilters(context),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickRange(context),
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, c) {
          final isMobile = c.maxWidth < 700;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: isMobile
                ? _buildList(reservations)
                : _buildGrid(reservations),
          );
        },
      ),
    );
  }

  // 📱 MOBILE (lista de cards)
  Widget _buildList(List<Reservation> data) {
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _card(i, data[i], compact: true),
    );
  }

  // 💻 DESKTOP (grid de cards)
  Widget _buildGrid(List<Reservation> data) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: GridView.builder(
        itemCount: data.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisExtent: 200,
          maxCrossAxisExtent: 800,
          childAspectRatio: 4,
          crossAxisSpacing: 25,
          mainAxisSpacing: 25,
        ),
        itemBuilder: (_, i) => _card(i, data[i], compact: false),
      ),
    );
  }

  // 🧾 CARD UNIFICADA
  Widget _card(int index, Reservation r, {required bool compact}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusChip(r.estado),
              Text(
                r.estado,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          // _dataClient(r),
          //CLIENT INFO
          Text(
            "${r.client.name} ",

            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          //ROOM INFO
          Text(
            r.rooms.map((room) => "${room.number} - ${room.cat}").join("  |  "),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          // DATE RANGE
          Text(
            "${r.fecha_in} → ${r.fecha_out}",
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          const Spacer(),
          // button VER
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  await _openDetail(r);
                  await getReservations();
                  setState(() {});
                },
                child: const Text("Ver Detalles"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🟡 STATUS CHIP
  Widget _statusChip(String status) {
    Color color = switch (status) {
      "PENDIENTE" => Colors.amber,
      "CONFIRMADA" => Colors.green,
      "NO_SHOW" => Colors.red,
      "CHECK_IN" => const Color.fromARGB(255, 58, 166, 255),
      "CHECK_OUT" => Colors.grey,
      "CANCELADA" => Colors.grey,
      "REJECTED" => const Color.fromARGB(255, 255, 102, 0),
      _ => Colors.white24,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  // 🔍 FILTROS
  void _openFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Orden", style: TextStyle(color: Colors.white)),

                  RadioListTile(
                    value: "estado",
                    groupValue: sortMode,
                    onChanged: (v) => setState(() => sortMode = v!),
                    title: const Text(
                      "Por estado",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  RadioListTile(
                    value: "fecha",
                    groupValue: sortMode,
                    onChanged: (v) => setState(() => sortMode = v!),
                    title: const Text(
                      "Por fecha",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Aplicar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 📅 RANGO FECHAS
  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => range = picked);
    }
  }

  Future<void> _openDetail(Reservation r) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
        ), // margen externo
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500, // controla ancho máximo del dialog
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._details(r),
                  const SizedBox(height: 36),

                  // IMAGEN (click para ampliar)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: InteractiveViewer(
                                child: Image.network(
                                  "http://${GlobalVar.ip}:3000/uploads/proofs/${r.proof_url}",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 120, // 🔥 controla tamaño aquí
                          height: 120,
                          child: Image.network(
                            "http://${GlobalVar.ip}:3000/uploads/proofs/${r.proof_url}",
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Text("Error")),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BOTONES
                  PermissionGate(
                    permisos: ['gestionar_reservas', 'ver_reservas'],
                    child: buildBotones(r),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //CONTENIDO
  List<Widget> _details(Reservation r) {
    return [
      // HEADER
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Reserva:  ${r.cod_reserva}",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => GoRouter.of(context).pop(),
          ),
        ],
      ),

      const SizedBox(height: 8),

      // CLIENTE
      Text(r.client.name, style: Theme.of(context).textTheme.bodyLarge),
      Text("CI: ${r.client.ci}", style: Theme.of(context).textTheme.bodySmall),
      Text(
        "Nacimiento: ${r.client.birth}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        "Dirección: ${r.client.addr}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        "Teléfono: ${r.client.phone}",
        style: Theme.of(context).textTheme.bodySmall,
      ),

      const SizedBox(height: 12),

      //ESTANCIA
      Text("Estancia:", style: Theme.of(context).textTheme.bodyLarge),
      Text("Estado: ${r.estado}", style: Theme.of(context).textTheme.bodySmall),
      Text(
        "Personas: ${r.n_personas}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        "fecha de reserva: ${r.fecha_reserva}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        "total: Bs ${r.total}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        "anticipo: Bs ${r.anticipo}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        "metodo de pago: ${r.metodo_pago}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        'check-in: ${r.fecha_in}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        'check-out: ${r.fecha_out}',
        style: Theme.of(context).textTheme.bodySmall,
      ),

      SizedBox(height: 12),
      Text('Habitaciones:', style: Theme.of(context).textTheme.bodyLarge),
      // INFO
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...r.rooms.map(
            (room) => Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${room.number} - ${room.cat} - ${room.price}Bs ",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      "Capacidad: ${room.slots} personas",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      "Features: ${room.features} ",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  // Widget _infoItem(String title, String value, BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title, style: Theme.of(context).textTheme.labelLarge),
  //       const SizedBox(height: 4),
  //       Text(value, style: Theme.of(context).textTheme.bodySmall),
  //     ],
  //   );
  // }

  //MODULO
  Widget buildBotones(Reservation r) {
    switch (r.estado) {
      case "PENDIENTE":
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await context.read<HotelProvider>().modificarReserva(
                  r.cod_reserva,
                  "CONFIRMADA",
                  "Hecho",
                );
                GoRouter.of(context).pop();
              },
              child: const Text("Confirmar"),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                await _pedirMotivo().then((motivo) async {
                  if (motivo != null && motivo.isNotEmpty) {
                    await context.read<HotelProvider>().modificarReserva(
                      r.cod_reserva,
                      "REJECTED",
                      motivo,
                    );
                    GoRouter.of(context).pop();
                  } else {
                    MySnackbar.info(context, "Cancelado por falta de motivo");
                  }
                });
              },
              child: const Text("Rechazar"),
            ),
          ],
        );
      case "NO_SHOW":
        return ElevatedButton(
          onPressed: () async {
            await context.read<HotelProvider>().modificarReserva(
              r.cod_reserva,
              "CANCELADA",
              "Cliente ausente, reserva cancelada en ${DateTime.now().toIso8601String()}",
            );
            GoRouter.of(context).pop();
          },
          child: const Text("Cancelar reserva"),
        );
      case "CONFIRMADA":
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () async {
                await context.read<HotelProvider>().modificarReserva(
                  r.cod_reserva,
                  "CANCELADA",
                  "Cliente ausente, reserva cancelada en ${DateTime.now().toIso8601String()}",
                );
                GoRouter.of(context).pop();
              },
              child: const Text("Cancelar reserva"),
            ),
            SizedBox(width: 15),
            OutlinedButton(
              onPressed: () {
                GoRouter.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );

      default:
        return OutlinedButton(
          onPressed: () {
            GoRouter.of(context).pop();
          },
          child: const Text("Cerrar"),
        );
    }
  }

  Future<String?> _pedirMotivo() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Motivo de rechazo"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Escribe el motivo...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text;
              Navigator.of(context).pop(text);
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }
}
