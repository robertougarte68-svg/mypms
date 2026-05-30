import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/data/categoria_tree_select.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/providers/user_provider.dart';
import 'package:my_pms/utils/my_menu_bar.dart';
import 'package:my_pms/utils/my_snackbar.dart';
import 'package:provider/provider.dart';

class Cuentas extends StatefulWidget {
  const Cuentas({super.key});

  @override
  State<Cuentas> createState() => _CuentasState();
}

class _CuentasState extends State<Cuentas> {
  TextEditingController xdiasCtrl = TextEditingController();
  int selected = 0;
  final montctrl = TextEditingController();
  final desctrl = TextEditingController();
  Map<String, dynamic> cashfields = {
    "monto": null,
    "user_id": null,
    "metodo": null,
    "tipo": null,
    "cat_id": null,
    "descripcion": null,
  };
  List<Categoria> cats = [];
  List<Map<String, dynamic>> cashFlow = [];
  late HotelProvider hotelProv;
  late AuthProvider authProv;
  late UserProvider userlProv;
  String? filtro;
  double ingresos = 0;
  double egresos = 0;
  double balance = 0;
  double saldo = 0;

  DateTime? t0;
  DateTime? tf;
  int? days = 1;

  @override
  void initState() {
    super.initState();
    hotelProv = context.read<HotelProvider>();
    authProv = context.read<AuthProvider>();
    userlProv = context.read<UserProvider>();
    // days = 5;
    _loadBalance();
    _loadCategorias();
    _loadCashFlow(null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBalance() async {
    ingresos = await hotelProv.getIngresos(days, t0, tf);
    egresos = await hotelProv.getEgresos(days, t0, tf);
    saldo = await hotelProv.getSaldo(days, t0, tf);
    balance = saldo + ingresos - egresos;

    setState(() {});
    // balance = ingresos - egresos + saldo;
  }

  Future<void> _loadCategorias() async {
    final data = await hotelProv.getCategorias();
    if (data.isEmpty) {
      MySnackbar.error(context, 'No se pudieron cargar las categorias');
      return;
    }
    cats = data.map<Categoria>((json) {
      return Categoria(
        id: json['id'],
        nombre: json['nombre'],
        parentId: json['parent_id'],
      );
    }).toList();
  }

  Future<void> _loadCashFlow(String? filter) async {
    final data = await hotelProv.getCashFlow(filter ?? 'Dia');
    if (data == null) {
      cashFlow = [];
      MySnackbar.error(
        context,
        'No se pudieron cargar los movimientos cashflow',
      );
      return;
    }
    cashFlow = data;
    // print(cashFlow);
    setState(() {
      // _loadParams();
    });
  }

  Future<String> _getCategoria(int catId) async {
    return await hotelProv.getCategory(catId) ?? 'Categoría desconocida';
  }

  Future<String> _getUser(int userId) async {
    return await userlProv.getUser(userId) ?? 'Usuario desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return isMobile ? mobileView() : desktopView(Theme.of(context));
      },
    );
  }

  Widget mobileView() {
    return Center(child: Text('Cuentas - Mobile View'));
  }

  Widget desktopView(ThemeData theme) {
    return Column(
      children: [
        //MENU - FILTROS
        MyMenuBar(
          items: [
            MenuItemData(icon: Icons.today, label: "Dia"),
            MenuItemData(icon: Icons.calendar_view_week, label: "Semana"),
            MenuItemData(icon: Icons.calendar_month, label: "Mes"),
          ],
          selectedIndex: selected,
          onSelected: (i) async {
            selected = i;

            switch (i) {
              case 0: // DIA
                days = 1;
                t0 = null;
                tf = null;
                await _loadBalance();
                await _loadCashFlow("Dia");
                break;

              case 1: // SEMANA
                days = null;
                tf = DateTime.now(); //hoy
                t0 = tf!.subtract(
                  //lunes
                  Duration(days: tf!.weekday - DateTime.monday),
                );
                // print('tf: $tf   t0: $t0 ');
                await _loadBalance();
                await _loadCashFlow("Semana");
                break;

              case 2: // MES
                days = null;
                tf = DateTime.now();
                t0 = DateTime(tf!.year, tf!.month, 1);
                // print('tf: $tf   t0: $t0 ');
                await _loadBalance();
                await _loadCashFlow("Mes");
                break;
            }
            setState(() {});
          },
          others: [
            // X DIAS
            SizedBox(
              height: 30,
              width: 80,
              child: TextFormField(
                controller: xdiasCtrl,

                decoration: InputDecoration(
                  hint: Text(
                    'x dias',
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (int.tryParse(xdiasCtrl.text) == null) {
                  MySnackbar.error(context, "x dias debe ser numero");
                  return;
                } else {
                  days = int.tryParse(xdiasCtrl.text);
                  t0 = null;
                  tf = null;
                  _loadBalance();
                }
              },
              icon: Icon(Icons.search),
            ),
            // RANGO
            SizedBox(width: 5),
            IconButton(onPressed: () {}, icon: Icon(Icons.calendar_month)),
          ],
        ),
        SizedBox(height: 20),

        /// FILA 1: indicadores
        Container(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
          padding: EdgeInsets.all(30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Indicador circular
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 200,
                  child: Center(child: circularIndicator(ingresos, egresos)),
                ),
              ),

              SizedBox(width: 16),

              /// Tarjetas
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    //INGRESOS Y EGRESOS DEL DIA
                    Row(
                      children: [
                        Expanded(
                          child: financeCard(
                            context: context,
                            title: "Ingresos",
                            value: ingresos.toString(),
                            accentColor: Colors.green,
                            icon: Icons.trending_up,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: financeCard(
                            context: context,
                            title: "Egresos",
                            value: egresos.toString(),
                            accentColor: Colors.redAccent,
                            icon: Icons.trending_down,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //SALDO AYER - BALANCE DEL DIA
                    Row(
                      children: [
                        Expanded(
                          child: financeCard(
                            context: context,
                            title: "Saldo Anterior",
                            value: saldo.toString(),
                            accentColor: const Color.fromARGB(255, 255, 238, 0),
                            icon: Icons.account_balance_wallet,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: financeCard(
                            context: context,
                            title: "Balance",
                            value: balance.toString(),
                            accentColor: const Color.fromARGB(255, 0, 191, 221),
                            icon: Icons.account_balance,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        /// FILA 2: historial
        Expanded(
          child: Card(
            child: Column(
              children: [
                /// Header (filtros + botón)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text("Historial"),
                      SizedBox(width: 20),

                      /// Filtros
                      // DropdownButton(
                      //   hint: Text(filtro ?? 'Filtrar por'),
                      //   // value: filtro,
                      //   items: ["Dia", "Semana", "Mes", "Año"]
                      //       .map(
                      //         (e) => DropdownMenuItem(value: e, child: Text(e)),
                      //       )
                      //       .toList(),
                      //   onChanged: (v) {
                      //     filtro = v;
                      //     _loadCashFlow(filtro);
                      //   },
                      // ),
                      Spacer(),

                      /// Botón nuevo
                      ElevatedButton(
                        onPressed: () async {
                          await _openDialog(context);
                          await _loadCashFlow(filtro);
                          await _loadBalance();
                          // recargar movimientos después de agregar uno nuevo
                          setState(() {});
                          ;
                        },
                        child: Text("Nuevo"),
                      ),
                    ],
                  ),
                ),

                Divider(),

                /// Tabla / lista
                Expanded(
                  child: cashFlow.isEmpty
                      ? Center(child: Text("No hay movimientos registrados"))
                      : ListView.builder(
                          itemCount: cashFlow.length,
                          itemBuilder: (_, i) => ListTile(
                            leading: Icon(
                              Icons.paid,
                              color: cashFlow[i]['tipo'] == 'Ingreso'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: FutureBuilder<String>(
                              future: _getCategoria(cashFlow[i]['cat_id']),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    '${snapshot.data!}  ${cashFlow[i]['tipo'] == 'Ingreso' ? '+' : '-'} Bs: ${cashFlow[i]['monto']} (${cashFlow[i]['metodo']}) ',
                                  );
                                }
                                return Text("Cargando...");
                              },
                            ),

                            subtitle: Text(' ${cashFlow[i]['fecha']}'),
                            trailing: SizedBox(
                              width: 200,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FutureBuilder<String>(
                                  future: _getUser(cashFlow[i]['user_id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Text(
                                        'Por: ${snapshot.data!}\n${cashFlow[i]['descripcion']}',
                                      );
                                    }
                                    return Text("Cargando...");
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget financeCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color accentColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Chip de color vivo
          // Container(
          //   width: 20,
          //   height: 40,
          //   decoration: BoxDecoration(
          //     color: accentColor,
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          // ),
          const SizedBox(width: 5),

          if (icon != null) Icon(icon, color: accentColor, size: 40),

          if (icon != null) const SizedBox(width: 30),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 4),
              //MONTO
              Text(
                '$value  Bs.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nuevo movimiento"),
                // seleccionar categoria
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CategoriaTreeSelect(
                    categorias: cats,
                    onSelected: (cat) {
                      cashfields["cat_id"] = cat.id;
                      print("Categoría seleccionada: ${cat.nombre}");
                    },
                  ),
                ),
                // monto
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: montctrl,
                    decoration: InputDecoration(labelText: "Monto"),
                  ),
                ),
                //metodo de pago
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField(
                    hint: Text('Metodo de pago'),
                    items: ["Efectivo", "Qr", "Tarjeta"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      cashfields["metodo"] = v;
                    },
                  ),
                ),
                // tipo movimiento
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField(
                    hint: Text('Tipo de movimiento'),
                    items: ["Ingreso", "Egreso"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      cashfields["tipo"] = v;
                    },
                  ),
                ),
                // detalle
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: desctrl,
                    decoration: InputDecoration(labelText: "Detalle"),
                  ),
                ),
                // botones guardar-cancelar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //guardar
                      ElevatedButton(
                        onPressed: () async {
                          if (!_comprobarCampos()) {
                            MySnackbar.error(
                              context,
                              'Por favor complete  los campos correctamente',
                            );
                            return;
                          }
                          cashfields["monto"] = double.tryParse(montctrl.text);
                          cashfields["user_id"] = authProv.userId;
                          cashfields["descripcion"] = desctrl.text;
                          if (await hotelProv.addCashFlow(cashfields)) {
                            MySnackbar.success(
                              context,
                              'Movimiento registrado',
                            );
                          } else {
                            MySnackbar.error(
                              context,
                              'Error en hotelProv.addCashFlow',
                            );
                          }
                          cashfields.updateAll((key, value) => null);

                          context.pop();
                        },
                        child: Text("Guardar"),
                      ),
                      // cancelar
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            context.pop();
                          });
                        },
                        child: Text("Cancelar"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } // fin método _openDialog

  bool _comprobarCampos() {
    if (cashfields["cat_id"] == null ||
        cashfields["metodo"] == null ||
        cashfields["tipo"] == null ||
        montctrl.text.isEmpty ||
        double.tryParse(montctrl.text) == null ||
        desctrl.text.isEmpty) {
      return false;
    }
    return true;
  }

  Widget circularIndicator(double ingresos, double egresos) {
    double balance = ingresos - egresos;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800),
      builder: (context, value, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            /// DONUT
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50, // clave donut
                startDegreeOffset: -90,
                sections: [
                  /// INGRESOS
                  PieChartSectionData(
                    value: ingresos * value,
                    color: Colors.green,
                    showTitle: false,
                    radius: 20,
                  ),

                  /// EGRESOS
                  PieChartSectionData(
                    value: egresos * value,
                    color: Colors.red,
                    showTitle: false,
                    radius: 20,
                  ),
                ],
              ),
            ),

            /// CENTRO DINÁMICO
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Flujo",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  "Bs ${balance.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
} // fin clase _CuentasState
