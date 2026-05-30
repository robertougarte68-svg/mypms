import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/providers/user_provider.dart';
import 'package:my_pms/utils/my_snackbar.dart';
import 'package:provider/provider.dart';

class JoinHotelScreen extends StatefulWidget {
  const JoinHotelScreen({super.key});

  @override
  State<JoinHotelScreen> createState() => _JoinHotelScreenState();
}

class _JoinHotelScreenState extends State<JoinHotelScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hotelCodeCtrl = TextEditingController();
  String? _selectedRol;

  final List<String> _roles = [
    'housekeeping',
    'recepcionista',
    'administrador',
    'gerente',
  ];

  late RoomProvider roomProv;
  late AuthProvider authProv;
  late UserProvider userProv;
  late HotelProvider hotelProv;
  @override
  void initState() {
    super.initState();
    roomProv = context.read<RoomProvider>();
    authProv = context.read<AuthProvider>();
    userProv = context.read<UserProvider>();
    hotelProv = context.read<HotelProvider>();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _hotelCodeCtrl.dispose();

    super.dispose();
  }

  void _joinHotel() async {
    if (_hotelCodeCtrl.text.isEmpty || _selectedRol == null) {
      MySnackbar.error(context, "campos vacios");
      return;
    }
    final idHotel = await hotelProv.valitCode(_hotelCodeCtrl.text);
    if (idHotel is int) {
      final parche = {'hotel_id': idHotel, 'rol': _selectedRol};
      if (await userProv.patchUser(parche, authProv.username)) {
        authProv.hotel_id = idHotel;
        authProv.userRol = _selectedRol!;
        print("hotel_id  registrado en auth provider: ${authProv.hotel_id}");
        if (mounted) {
          MySnackbar.success(context, "Exito");
          GoRouter.of(context).go('/homepage');
        } else {
          print("problema de montado en join_hotel_screen (gohomepage)");
        }
        return;
      } else {
        print("problema con parchado de usuario actual en joinHotel");
        return;
      }
    } else {
      if (mounted) {
        print("el hotel no existe");
        MySnackbar.error(context, "el hotel no existe");
      } else {
        print("problema de montado en join_hotel_screen (hotel no existe)");
      }

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Unirse a Hotel")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Datos de acceso",
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _hotelCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Código del Hotel",
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedRol,
                    decoration: const InputDecoration(
                      labelText: "Rol de Usuario",
                    ),
                    items: _roles
                        .map(
                          (rol) =>
                              DropdownMenuItem(value: rol, child: Text(rol)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRol = value;
                      });
                    },
                  ),
                  const SizedBox(height: 40),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _joinHotel,
                          child: const Text("Unirse"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
