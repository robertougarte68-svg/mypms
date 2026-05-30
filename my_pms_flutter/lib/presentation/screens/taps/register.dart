import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:my_pms/data/client.dart';
import 'package:my_pms/data/room.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/client_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/utils/donut_chart.dart';
import 'package:my_pms/utils/my_snackbar.dart';
import 'package:provider/provider.dart';

enum FormaPago { efectivo, qr, otro }

class Huesped {
  TextEditingController cname;
  TextEditingController cci;
  TextEditingController cbirth;
  TextEditingController caddr;
  TextEditingController cphone;
  Map<String, dynamic> fields = {
    'name': '',
    'birth': '',
    'ci': '',
    'addr': '',
    'phone': 0,
  };

  Huesped({
    required this.cname,
    required this.cci,
    required this.cbirth,
    required this.caddr,
    required this.cphone,
  });
}

class MyRegister extends StatefulWidget {
  const MyRegister({super.key});

  @override
  State<MyRegister> createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  Room? selectedRoom;
  Key pageKey = UniqueKey();
  Client? buscado;
  bool loading = false;
  List<Huesped> huespedes = [
    Huesped(
      cname: TextEditingController(),
      cci: TextEditingController(),
      cbirth: TextEditingController(),
      caddr: TextEditingController(),
      cphone: TextEditingController(),
    ),
  ];
  List<GlobalKey<FormState>> kforms = [GlobalKey<FormState>()];
  late GlobalKey<FormState> formKeyStay;

  late TextEditingController roomControl;
  late TextEditingController priceControl;

  late List<String> resultados;
  late ClientProvider clientProv;
  late AuthProvider authProvider;
  late RoomProvider roomProv;
  late HotelProvider hotelProv;

  late String? selectedMode;

  FormaPago? formaPago = FormaPago.efectivo;
  Map<String, dynamic> stayFields = {
    'n_room': 0,
    'id_room': 0,
    'mode': '',
    'tarifa': 0,
    'pay_method': '',
  };

  @override
  void initState() {
    super.initState();

    formKeyStay = GlobalKey<FormState>();
    roomControl = TextEditingController();
    priceControl = TextEditingController();

    selectedMode = null;
    clientProv = context.read<ClientProvider>();
    authProvider = context.read<AuthProvider>();
    roomProv = context.read<RoomProvider>();
    hotelProv = context.read<HotelProvider>();
    resultados = [];
  }

  @override
  void dispose() {
    roomControl.dispose();
    priceControl.dispose();
    for (var h in huespedes) {
      h.cname.dispose();
      h.cci.dispose();
      h.cbirth.dispose();
      h.caddr.dispose();
      h.cphone.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return !loading
        ? LayoutBuilder(
            key: pageKey,
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;
              if (isMobile) {
                //MOVIL
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        formulario(theme),
                        //TODO integrar seguridad de admision
                        //TODO integrar historial de cliente
                        SizedBox(height: 100),
                        Text(
                          "Seguridad de Admision",
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                //ESCRITORIO
                return Row(
                  children: [
                    //FORM DE REGISTRO
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: formulario(theme),
                      ),
                    ),
                    //HISTORIAL Y ADMISION
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: buscado != null
                            ? SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //  _seguridadAdmin(),
                                    SizedBox(height: 10),
                                    ..._historial(theme),
                                  ],
                                ),
                              )
                            : Center(
                                child: Text(
                                  'Busque un cliente para ver detalles',
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }
            },
          )
        : Container(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator()),
          );
  }

  List<Widget> _historial(ThemeData theme) {
    return [
      detailItem(context, "Nombre", buscado!.name),
      detailItem(context, "Edad", buscado!.birth ?? 'null'),
      detailItem(context, "Direccion", buscado!.addr),
      detailItem(context, "Top-Ingresos", "10"),
      SizedBox(height: 20),
      //TABLA
      SizedBox(
        // color: theme.shadowColor,
        height: 200,
        width: 500,
        child: DataTable2(
          dataRowHeight: 40,
          headingRowHeight: 40,
          headingRowColor: WidgetStateProperty.all(
            theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          dataRowColor: WidgetStateProperty.all(theme.colorScheme.surface),
          columns: [
            DataColumn2(label: Text('')),
            DataColumn2(label: Text('Visitas'), size: ColumnSize.S),
            DataColumn2(label: Text('Ingresos'), size: ColumnSize.S),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(Text('Last 30 days:')),
                DataCell(Text('${buscado!.statics!['stats']!['30'][0]}')),
                DataCell(Text('${buscado!.statics!['stats']!['30'][1]}')),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Last 90 days:')),
                DataCell(Text('${buscado!.statics!['stats']!['90'][0]}')),
                DataCell(Text('${buscado!.statics!['stats']!['90'][1]}')),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Last 365 days:')),
                DataCell(Text('${buscado!.statics!['stats']!['365'][0]}')),
                DataCell(Text('${buscado!.statics!['stats']!['365'][1]}')),
              ],
            ),
          ],
        ),
      ),
      // SizedBox(height: 30),
      Text(
        "Preferencias:",
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      DonutChart(
        data: [
          DonutData(
            label: "ESTANDAR",
            value:
                buscado!.statics['cats']['ESTANDAR'] /
                buscado!.statics['stats']['365'][0],
            color: Colors.red,
          ),
          DonutData(
            label: "SUPERIOR",
            value:
                buscado!.statics['cats']['SUPERIOR'] /
                buscado!.statics['stats']['365'][0],
            color: Colors.blue,
          ),
          DonutData(
            label: "DELUX",
            value:
                buscado!.statics['cats']['DELUX'] /
                buscado!.statics['stats']['365'][0],
            color: Colors.green,
          ),
          DonutData(
            label: "SUITE",
            value:
                buscado!.statics['cats']['SUITE'] /
                buscado!.statics['stats']['365'][0],
            color: Colors.orange,
          ),
        ],
      ),
    ];
  }

  Widget detailItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget formulario(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          //FORMULARIO DE ESTANCIA
          Card(
            child: Form(
              key: formKeyStay,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //ESTANCIA
                  Text(
                    "REGISTRO DE ESTANCIA:",
                    style: theme.textTheme.titleMedium,
                  ),
                  //numero de habitacion
                  formField(
                    stayFields,
                    'Numero de habitacion',
                    true,
                    'n_room',
                    roomControl,
                    "0",
                  ),
                  //modalidad room
                  Container(
                    margin: EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      value: selectedMode, //valor inicial
                      hint: Text("Seleccione modalidad"),
                      items: ["Temporal1", "Temporal2", "Normal"]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value;
                        });
                      },
                    ),
                  ),
                  //tarifa de estancia
                  formField(
                    stayFields,
                    'Tarifa',
                    true,
                    'tarifa',
                    priceControl,
                    "0 Bs.",
                  ),
                  //qr o efectivo
                  Container(
                    margin: EdgeInsets.all(8.0),
                    child: SegmentedButton<FormaPago>(
                      // multiSelectionEnabled: true,
                      segments: const [
                        ButtonSegment(
                          value: FormaPago.efectivo,
                          label: Text('Efectivo'),
                        ),
                        ButtonSegment(value: FormaPago.qr, label: Text('QR')),
                      ],
                      selected: {formaPago!},
                      onSelectionChanged: (Set<FormaPago> value) {
                        setState(() {
                          formaPago = value.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              ...huespedes.asMap().entries.map((entry) {
                int i = entry.key;
                Huesped h = entry.value;

                return Card(
                  child: Form(
                    key: kforms[i],
                    child: Column(
                      children: [
                        //TITULO Y BOTON DE ELIMINAR HUÉSPED
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("HUESPED ${i + 1}"),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (huespedes.length == 1) {
                                    MySnackbar.show(
                                      context,
                                      message: "Debe haber al menos un huésped",
                                      backgroundColor: Colors.white,
                                    );
                                    return;
                                  }
                                  huespedes[i].cname.dispose();
                                  huespedes[i].cci.dispose();
                                  huespedes[i].cbirth.dispose();
                                  huespedes[i].caddr.dispose();
                                  huespedes[i].cphone.dispose();

                                  huespedes.removeAt(i);
                                  kforms.removeAt(i);
                                });
                              },
                              icon: Icon(Icons.delete),
                            ),
                          ],
                        ),
                        //NOMBRE HUESPED
                        formField(
                          h.fields,
                          'Nombre',
                          false,
                          'name',
                          h.cname,
                          "",
                        ),
                        //CARNET HUESPED
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: formField(
                                h.fields,
                                'Numero de carnet',
                                true,
                                'ci',
                                h.cci,
                                '',
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (h.cci.text.length > 5) {
                                    var cliente = await clientProv
                                        .getClientByCi(h.cci.text);

                                    if (cliente.isNotEmpty) {
                                      h.cname.text = cliente["name"] ?? "nulo";
                                      h.cbirth.text = cliente["birth"]
                                          .toString();
                                      h.caddr.text =
                                          cliente["addr"] ??
                                          "defecto instead null";
                                      h.cphone.text = cliente["phone"]
                                          .toString();

                                      buscado = Client(
                                        id: cliente['id'],
                                        name: cliente['name'],
                                        birth: cliente['birth'],
                                        ci: cliente['ci'],
                                        addr: cliente['addr'],
                                        phone: cliente['phone'],
                                      );
                                      buscado!.statics = await clientProv
                                          .getStatics(buscado!.id!);
                                      setState(() {
                                        print('${buscado!.statics}');
                                      });
                                    } else {
                                      if (context.mounted) {
                                        MySnackbar.info(
                                          context,
                                          "Cliente No Registrado",
                                        );
                                        print("cliente no registrado");
                                      } else {
                                        print(
                                          "cliente no registrado.  & problema de montado",
                                        );
                                      }
                                    }
                                  }
                                },
                                child: Text("Buscar"),
                              ),
                            ),
                          ],
                        ),
                        //BIRTH HUESPED
                        formField(
                          h.fields,
                          "Fecha de Nacimiento",
                          false,
                          'birth',
                          h.cbirth,
                          "AAAA-MM-DD",
                        ),
                        //ADDR Y PHONE HUESPED
                        formField(
                          h.fields,
                          'Direccion',
                          false,
                          'addr',
                          h.caddr,
                          "",
                        ),
                        formField(
                          h.fields,
                          'Telefono',
                          true,
                          'phone',
                          h.cphone,
                          "",
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          //BOTON DE AGREGAR HUÉSPED
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  huespedes.add(
                    Huesped(
                      cname: TextEditingController(),
                      cci: TextEditingController(),
                      cbirth: TextEditingController(),
                      caddr: TextEditingController(),
                      cphone: TextEditingController(),
                    ),
                  );
                  kforms.add(GlobalKey<FormState>());
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Text("Nuevo (+)"),
              ),
            ),
          ),
          //BOTON DE REGISTRAR
          ElevatedButton(
            onPressed: () async {
              setState(() {
                loading = true;
              });
              //control de formularios huespedes
              for (var k in kforms) {
                if (!k.currentState!.validate()) {
                  setState(() {
                    loading = false;
                  });
                  MySnackbar.error(
                    context,
                    "Por favor, corrija los errores en el formulario de huéspedes",
                  );

                  return;
                } else {
                  k.currentState!.save();
                }
              }

              //control de campos de estancia
              if (!formKeyStay.currentState!.validate()) {
                setState(() {
                  loading = false;
                });

                MySnackbar.error(
                  context,
                  "Por favor, corrija los errores en el formulario de estancia",
                );
                return;
              } else {
                formKeyStay.currentState!.save();
              }
              //COMIENZA SOLICITUDES AL SERVIDOR

              await _getIdRoom();

              //control de modalidad de estancia
              if (selectedMode != null) {
                stayFields['mode'] = selectedMode;
              } else {
                setState(() {
                  loading = false;
                });
                MySnackbar.error(context, "Seleccione una modalidad");
                return;
              }

              //guardando forma de pago
              if (formaPago == FormaPago.efectivo) {
                stayFields['pay_method'] = 'efectivo';
              } else {
                stayFields['pay_method'] = 'QR';
              }

              //REGISTROS EN LA DB Y NOTIFICAR CLIENTE MQTT
              await _registrarEnDB();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Text("Registrar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget formField(
    Map<String, dynamic> clientFields,
    String fnombre,
    bool? isNumb,
    String key,
    TextEditingController control,
    String hint,
  ) {
    return Container(
      margin: EdgeInsets.all(8.0),
      child: TextFormField(
        // initialValue: "",
        controller: control,
        decoration: InputDecoration(labelText: fnombre, hintText: hint),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            if (isNumb != null) {
              if ((!isNumb)) {
                //si es string:
                if (int.tryParse(value) != null) {
                  return 'No permitido numeros';
                }
              } else {
                //si es numero:
                if (int.tryParse(value) == null) {
                  return 'Solo valor numerico es permitido';
                }
              }
            } else {
              //TODO implementar validacion de fecha
            }
          } else {
            return '$fnombre obligatorio';
          }

          return null;
        },
        onSaved: (value) {
          if (isNumb != null && isNumb) {
            //numb
            clientFields[key] = int.tryParse(value!);
          } else if (isNumb == false) {
            //string
            clientFields[key] = value;
          }
        },
      ),
    );
  }

  void resetPage() {
    roomControl.dispose();
    priceControl.dispose();

    for (var h in huespedes) {
      h.cname.dispose();
      h.cci.dispose();
      h.cbirth.dispose();
      h.caddr.dispose();
      h.cphone.dispose();
    }

    formKeyStay = GlobalKey<FormState>();

    roomControl = TextEditingController();
    priceControl = TextEditingController();

    selectedMode = null;
    formaPago = FormaPago.efectivo;
    buscado = null;

    stayFields = {
      'n_room': 0,
      'id_room': 0,
      'mode': '',
      'tarifa': 0,
      'pay_method': '',
    };

    huespedes = [
      Huesped(
        cname: TextEditingController(),
        cci: TextEditingController(),
        cbirth: TextEditingController(),
        caddr: TextEditingController(),
        cphone: TextEditingController(),
      ),
    ];

    kforms = [GlobalKey<FormState>()];
  }

  Future<void> _getIdRoom() async {
    try {
      //obtener id_room
      selectedRoom = await roomProv.getRoom(
        int.parse(roomControl.text),
        authProvider.hotel_id!,
      );

      if (selectedRoom == null) {
        setState(() {
          loading = false;
        });
        MySnackbar.error(context, "La Habitacion no existe");
        return;
      } else if (selectedRoom!.state != 'libre') {
        setState(() {
          loading = false;
        });
        MySnackbar.error(
          context,
          "La Habitacion no esta disponible en estos momentos",
        );
        return;
      }

      stayFields['id_room'] = selectedRoom!.id;
    } catch (e) {
      setState(() {
        loading = false;
      });
      // print(e);
      MySnackbar.error(context, "Error en solicitud al servidor para ID room");
      return;
    }
  }

  Future<void> _registrarEnDB() async {
    try {
      //guardando estancia
      final idStay = await hotelProv.writeStay(stayFields);

      //guardando huespedes
      List<int> ids = [];
      for (var h in huespedes) {
        print(h.fields);
        ids.add(await clientProv.writeClient(h.fields));
      }
      print(ids);

      //guardando relacion estancia-huespedes
      if (await hotelProv.writeCiS(idStay, ids)) {
        print('relacion estancia-clientes escrita');
      } else {
        print('problema con relacion:  estancia-cliente en register');
        return;
      }

      //actualizar estado room
      selectedRoom!.state = 'ocupado';
      roomProv.patchRoomItem({'state': 'ocupado'}, selectedRoom!.id);
    } catch (e) {
      MySnackbar.error(
        context,
        "Error al registrar la estancia y clientes en el servidor",
      );
      return;
    }
    buscado!.statics = await clientProv.getStatics(buscado!.id!);
    setState(() {
      loading = false;
      // print('${buscado!.statics}');
    });
    MySnackbar.success(context, "Registro exitoso");
    setState(() {
      resetPage();
    });
  }
}
