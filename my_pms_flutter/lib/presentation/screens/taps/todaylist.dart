import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/data/global_var.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/utils/my_menu_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class TodayList extends StatefulWidget {
  const TodayList({super.key});

  @override
  State<TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<TodayList> {
  final pdf = pw.Document();
  DateTime? start;
  DateTime? end;
  int menuItem = 0;
  late HotelProvider hotelProv;
  late AuthProvider authProv;
  @override
  void initState() {
    super.initState();
    hotelProv = context.read<HotelProvider>();
    authProv = context.read<AuthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setToday();

      await _buscar(hotelProv, authProv);

      setState(() {});
    });
  }

  void _setToday() {
    final now = DateTime.now();
    start = DateTime(now.year, now.month, now.day);
    end = now;
  }

  void _setWeek() {
    final now = DateTime.now();
    start = now.subtract(Duration(days: 7));
    end = now;
  }

  void _setMonth() {
    final now = DateTime.now();
    start = DateTime(now.year, now.month, 1);
    end = now;
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      setState(() {
        start = range.start;
        end = range.end;
      });
    }
  }

  Future<void> _buscar(hotelProv, authProv) async {
    if (start != null && end != null) {
      await hotelProv.getStaysByRange(start!, end!, authProv.hotel_id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelProv = context.watch<HotelProvider>();
    final authProv = context.read<AuthProvider>();
    final roomProv = context.read<RoomProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // // filtros
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //   color: Theme.of(context).colorScheme.onPrimary,
        //   child: Row(
        //     spacing: 10,
        //     children: [
        //       TextButton(
        //         onPressed: () async {
        //           setState(_setToday);
        //           await _buscar(hotelProv, authProv);
        //         },
        //         child: const Text("Hoy"),
        //       ),
        //       TextButton(
        //         onPressed: () async {
        //           setState(_setWeek);
        //           await _buscar(hotelProv, authProv);
        //         },
        //         child: const Text("Semana"),
        //       ),
        //       TextButton(
        //         onPressed: () async {
        //           setState(_setMonth);
        //           await _buscar(hotelProv, authProv);
        //         },
        //         child: const Text("Mes"),
        //       ),
        //       Expanded(child: SizedBox(height: 10)),
        //       TextButton(onPressed: _pickRange, child: const Text("Rango")),
        //       TextButton(
        //         onPressed: () async {
        //           await _buscar(hotelProv, authProv);
        //         },
        //         child: const Text("Buscar"),
        //       ),
        //     ],
        //   ),
        // ),
        MyMenuBar(
          items: [
            MenuItemData(icon: Icons.today, label: "Dia"),
            MenuItemData(icon: Icons.calendar_view_week, label: "Semana"),
            MenuItemData(icon: Icons.calendar_month, label: "Mes"),
          ],
          selectedIndex: menuItem,
          onSelected: (i) async {
            menuItem = i;

            switch (i) {
              case 0: // DIA
                setState(_setToday);
                await _buscar(hotelProv, authProv);
                break;

              case 1: // SEMANA
                setState(_setWeek);
                await _buscar(hotelProv, authProv);
                break;

              case 2: // MES
                setState(_setMonth);
                await _buscar(hotelProv, authProv);
                break;
            }
            setState(() {});
          },
          others: [
            Expanded(child: SizedBox(height: 10)),
            Text("RANGO", style: TextStyle(color: Colors.grey)),
            IconButton(onPressed: _pickRange, icon: Icon(Icons.calendar_month)),
            TextButton(
              onPressed: () async {
                await _buscar(hotelProv, authProv);
              },
              child: const Text("Buscar"),
            ),
            IconButton(
              onPressed: () {
                context.push("/printView", extra: hotelProv.stays);
              },
              icon: Icon(Icons.print),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // lista
        Expanded(
          child: hotelProv.stays == null
              ? Center(child: Text("Sin datos"))
              : ListView.builder(
                  itemCount: hotelProv.stays!['stays'].length,
                  itemBuilder: (context, i) {
                    final stay = hotelProv.stays!['stays'][i];
                    final clients = hotelProv.stays!['clients'][i];

                    return stayCard(stay, clients, hotelProv, roomProv);
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget stayCard(stay, clients, hotelProv, roomProv) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hab. ${stay['number']}",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Expanded(child: SizedBox(height: 10)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stay['date_out'] == null
                        ? Colors.green.withAlpha(50)
                        : Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stay['date_out'] == null ? "Activa" : "Finalizada",
                    style: TextStyle(
                      color: stay['date_out'] == null
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // CHECK-OUT
                if (stay['date_out'] == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      stay['date_out'] = DateTime.now()
                          .toString()
                          .split('.')
                          .first;

                      await hotelProv.checkoutStay(stay['id_stay']);
                      await roomProv.patchRoomItem({
                        'state': 'mantenimiento',
                      }, stay['id_room']);
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Check-out"),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            //BODY
            Wrap(
              alignment: WrapAlignment.start,
              children: [
                // CLIENTES
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clientes",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...clients.map<Widget>((c) {
                            return IntrinsicWidth(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // nombre (destacado)
                                    Text(
                                      c['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // datos en filas
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.badge,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text("CI: ${c['ci']}"),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.cake,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text("Edad/Fecha: ${c['birth']}"),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text("${c['phone']}"),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text("${c['addr']}"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                SizedBox(width: 40),
                //INFO Y FECHAS
                IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Estancia:",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      // INFO PRINCIPAL
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _chip(context, "Modo", stay['mode']),
                          _chip(context, "Tarifa", "${stay['tarifa']} Bs"),
                          _chip(context, "Pago", stay['pay_method']),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // FECHAS
                      Row(
                        children: [
                          Icon(Icons.login, size: 18, color: Colors.white54),
                          const SizedBox(width: 6),
                          Expanded(child: Text("${stay['date_in']}")),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: Colors.white54),
                          const SizedBox(width: 6),
                          Expanded(child: Text(stay['date_out'] ?? "En curso")),
                        ],
                      ),
                    ],
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
