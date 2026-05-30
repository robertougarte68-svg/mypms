enum ErrStates { loading, error, sucess }

class GlobalVar {
  // static String ip = "192.168.100.71"; //ethernet
  static String ip = "192.168.100.66"; //wifi
  // static String ip = "192.168.0.113"; //TUKUYPAQ2
  // static String ip = "192.168.100.248"; //TUKUYPAQ
}

List<String> staffRegister = ['recepcionista', 'gerente', 'propietario'];
List<String> staffEstancias = ['recepcionista', 'gerente', 'propietario'];
List<String> staffReservas = ['recepcionista', 'gerente', 'propietario'];
List<String> staffFinanzas = [
  'recepcionista',
  'admin',
  'gerente',
  'propietario',
];





                // Autocomplete<String>(
                //   optionsBuilder: (TextEditingValue value) async {
                //     if (value.text.isEmpty) {
                //       return const Iterable<String>.empty();
                //     }
                //     return await clientProv.searchSimilars(value.text);
                //   },
                //   onSelected: (selection) async {
                //     final cliente = await clientProv.getClient(selection);
                //     nombreControl.text = cliente["name"] ?? "nulo";
                //     edadControl.text = cliente["edad"].toString();
                //     ciControl.text = cliente["ci"].toString();
                //     addrControl.text = cliente["addr"] ?? "Punata";
                //     phoneControl.text = cliente["phone"].toString();
                //   },

                //   fieldViewBuilder:
                //       (
                //         BuildContext context,
                //         TextEditingController controller,
                //         FocusNode focusNode,
                //         VoidCallback onFieldSubmitted,
                //       ) {
                //         _controller = controller;
                //         return TextField(
                //           controller: controller,
                //           focusNode: focusNode,
                //           decoration: InputDecoration(
                //             labelText: 'Buscar por CI',
                //             prefixIcon: Icon(Icons.search), // ← icono aquí
                //             border: OutlineInputBorder(),
                //           ),
                //         );
                //       },
                // ),