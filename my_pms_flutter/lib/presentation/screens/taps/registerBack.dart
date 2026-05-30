import 'package:flutter/material.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/client_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/utils/my_snackbar.dart';
import 'package:provider/provider.dart';

enum FormaPago { efectivo, qr, otro }

class MyRegister extends StatefulWidget {
  const MyRegister({super.key});

  @override
  State<MyRegister> createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  late TextEditingController nombreControl;
  late TextEditingController edadControl;
  late TextEditingController ciControl;
  late TextEditingController addrControl;
  late TextEditingController phoneControl;

  late TextEditingController nombreControlSra;
  late TextEditingController edadControlSra;
  late TextEditingController ciControlSra;
  late TextEditingController addrControlSra;
  late TextEditingController phoneControlSra;

  late TextEditingController roomControl;
  late TextEditingController priceControl;

  late GlobalKey<FormState> formKey;

  late List<String> resultados;
  late ClientProvider clientProv;
  late AuthProvider authProvider;
  late RoomProvider roomProv;
  late HotelProvider hotelProv;

  late String? selectedMode;

  FormaPago? formaPago = FormaPago.efectivo;

  Map<String, dynamic> srFields = {
    'name': '',
    'birth': '',
    'ci': '',
    'addr': '',
    'phone': 0,
  };

  Map<String, dynamic> sraFields = {
    'name': '',
    'birth': '',
    'ci': '',
    'addr': '',
    'phone': 0,
  };

  Map<String, dynamic> stayFields = {
    'id_man': 0,
    'id_wom': 0,
    'id_room': 0,
    'mode': '',
    'tarifa': 0,
    'pay_method': '',
  };

  @override
  void initState() {
    super.initState();

    nombreControl = TextEditingController();
    edadControl = TextEditingController();
    ciControl = TextEditingController();
    phoneControl = TextEditingController();
    addrControl = TextEditingController();

    nombreControlSra = TextEditingController();
    edadControlSra = TextEditingController();
    ciControlSra = TextEditingController();
    phoneControlSra = TextEditingController();
    addrControlSra = TextEditingController();

    formKey = GlobalKey<FormState>();
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
    nombreControl.dispose();
    edadControl.dispose();
    ciControl.dispose();
    addrControl.dispose();
    phoneControl.dispose();
    roomControl.dispose();
    priceControl.dispose();
    nombreControlSra.dispose();
    edadControlSra.dispose();
    ciControlSra.dispose();
    addrControlSra.dispose();
    phoneControlSra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        if (isMobile) {
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
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(child: formulario(theme)),
                ),
              ),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  // scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
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
              ),
              // Expanded(child: Placeholder()), // Aquí podrías poner una imagen o algo decorativo
            ],
          );
        }
      },
    );
  }

  Widget formulario(ThemeData theme) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),

          //SENOR
          Text("Sr.", style: theme.textTheme.titleLarge), //Etiqueta Sr
          //NAME SR
          formField(srFields, 'Nombre', false, 'name', nombreControl, ""),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: formField(
                  srFields,
                  'Numero de carnet',
                  null,
                  'ci',
                  ciControl,
                  '',
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () async {
                  print("entrando al onPressed");
                  if (ciControl.text.length > 5) {
                    var cliente = await clientProv.getClientByCi(
                      ciControl.text,
                    );
                    print(' imprimiendo cliente: $cliente');
                    if (cliente.isNotEmpty) {
                      nombreControl.text = cliente["name"] ?? "nulo";
                      edadControl.text = cliente["birth"].toString();
                      addrControl.text =
                          cliente["addr"] ?? "defecto instead null";
                      phoneControl.text = cliente["phone"].toString();
                    } else {
                      if (context.mounted) {
                        MySnackbar.info(context, "Cliente No Registrado");
                        print("cliente no registrado");
                      } else {
                        print("cliente no registrado.  & problema de montado");
                      }
                    }
                  }
                },
                child: Text('Buscar'),
              ),
              // SizedBox(width: 20),
            ],
          ),
          SizedBox(height: 20),
          //BIRTH SR
          formField(
            srFields,
            "Fecha de Nacimiento",
            false,
            'birth',
            edadControl,
            "AAAA-MM-DD",
          ),
          SizedBox(height: 20),
          //ADDRESS SR
          formField(srFields, 'Direccion', false, 'addr', addrControl, ""),
          SizedBox(height: 20),
          //CONTACTO SR
          formField(
            srFields,
            'Numero de Contacto',
            true,
            'phone',
            phoneControl,
            "",
          ),
          SizedBox(height: 20),

          //SENORA
          SizedBox(height: 20),
          Text("Sra.", style: theme.textTheme.titleLarge),
          //NOMBRE SRA
          formField(sraFields, 'Nombre', false, 'name', nombreControlSra, ""),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: formField(
                  sraFields,
                  'Numero de carnet',
                  null,
                  'ci',
                  ciControlSra,
                  '',
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () async {
                  if (ciControlSra.text.length > 5) {
                    var cliente = await clientProv.getClientByCi(
                      ciControlSra.text,
                    );
                    if (cliente.isNotEmpty) {
                      nombreControlSra.text = cliente["name"] ?? "nulo";
                      edadControlSra.text = cliente["birth"].toString();
                      addrControlSra.text = cliente["addr"] ?? "instead nulll";
                      phoneControlSra.text = cliente["phone"].toString();
                    } else {
                      if (context.mounted) {
                        MySnackbar.info(context, "Cliente No Registrado");
                      }
                    }
                  }
                },
                child: Text('Buscar'),
              ),
              // SizedBox(width: 20),
            ],
          ),
          SizedBox(height: 20),
          //BIRTH SRA
          formField(
            sraFields,
            "Fecha de Nacimiento",
            false,
            'birth',
            edadControlSra,
            "AAAA-MM-DD",
          ),
          SizedBox(height: 20),
          //ADDR SRA
          formField(sraFields, 'Direccion', false, 'addr', addrControlSra, ""),
          SizedBox(height: 20),
          //CONTACTO SRA
          formField(
            sraFields,
            'Numero de Contacto',
            true,
            'phone',
            phoneControlSra,
            "",
          ),
          SizedBox(height: 20),
          //ESTANCIA
          Text("Estancia.", style: theme.textTheme.titleLarge),
          //NUMERO ROOM
          formField(
            stayFields,
            'Numero de Habitacion',
            true,
            'id_room',
            roomControl,
            "",
          ),
          SizedBox(height: 20),
          //MODALIDAD ROOM
          DropdownButton<String>(
            value: selectedMode,
            hint: Text("Seleccione modalidad"),
            items: ["Temporal1", "Temporal2", "Normal"]
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              setState(() {
                stayFields['mode'] = value;
                selectedMode = value;
              });
            },
          ),
          SizedBox(height: 20),
          //TARIFA ROOM
          formField(
            stayFields,
            'Tarifa',
            true,
            'tarifa',
            priceControl,
            " 0 Bs",
          ),
          SizedBox(height: 20),
          //QR O EFECTIVO
          SegmentedButton<FormaPago>(
            // multiSelectionEnabled: true,
            segments: const [
              ButtonSegment(value: FormaPago.efectivo, label: Text('Efectivo')),
              ButtonSegment(value: FormaPago.qr, label: Text('QR')),
            ],
            selected: {formaPago!},
            onSelectionChanged: (Set<FormaPago> value) {
              setState(() {
                formaPago = value.first;
              });
            },
          ),
          SizedBox(height: 20),

          //ENVIO
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                print(srFields);
                print(sraFields);
                final idSr = await clientProv.writeClient(srFields); //post
                final idSra = await clientProv.writeClient(sraFields);
                print('id hotel=${authProvider.hotel_id}');
                final idRoom = await roomProv.getId(
                  int.parse(roomControl.text),
                  authProvider.hotel_id!,
                );
                print('obteniendo idRoom: $idRoom');

                if (idRoom == null) {
                  if (context.mounted) {
                    MySnackbar.error(context, "La Habitacion no existe");
                    return;
                  } else {
                    print("Problema de montado en register.EnviarData");
                    return;
                  }
                }
                stayFields['id_man'] = idSr;
                stayFields['id_wom'] = idSra;
                stayFields['id_room'] = idRoom;

                //TODO implementar un banner de exito
                if (formaPago == FormaPago.efectivo) {
                  stayFields['pay_method'] = 'efectivo';
                } else {
                  stayFields['pay_method'] = 'QR';
                }
                print(stayFields);
                final idStay = await hotelProv.writeStay(stayFields);
                print("idStay: $idStay");
                if (await hotelProv.writeCiS(idStay, [idSr, idSra])) {
                  print('relacion estancia-clientes escrita');
                } else {
                  print('problema con relacion - estancia en register');
                }
                setState(() {
                  //TODO faltan limpiar campos
                  formKey.currentState!.reset();
                  selectedMode = null;
                  roomControl.clear();
                  priceControl.clear();

                  ciControl.clear();
                  addrControl.clear();
                  nombreControl.clear();
                  edadControl.clear();
                  phoneControl.clear();
                  ciControlSra.clear();
                  addrControlSra.clear();
                  nombreControlSra.clear();
                  edadControlSra.clear();
                  phoneControlSra.clear();
                });
                if (context.mounted) {
                  MySnackbar.success(context, "Registro Exitoso");
                }
                print("registro exitoso, pero problema con mounted");
              }
            },
            child: Text("Registrar Hoy"),
          ),
        ],
      ),
    );
  }

  TextFormField formField(
    Map<String, dynamic> clientFields,
    String fnombre,
    bool? isNumb,
    String key,
    TextEditingController control,
    String hint,
  ) {
    return TextFormField(
      // initialValue: "",
      controller: control,
      decoration: InputDecoration(labelText: fnombre, hintText: hint),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (isNumb != null) {
            if ((!isNumb)) {
              if (int.tryParse(value) != null) {
                return 'Valor numerico no permitido';
              }
            } else {
              if (int.tryParse(value) == null) {
                return 'Solo valor numerico';
              }
            }
          }
        } else {
          return '$fnombre obligatorio';
        }

        return null;
      },
      onSaved: (value) {
        if (isNumb != null && isNumb) {
          clientFields[key] = int.tryParse(value!);
        } else {
          clientFields[key] = value;
        }
      },
    );
  }
}
