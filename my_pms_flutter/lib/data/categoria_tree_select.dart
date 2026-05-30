import 'package:flutter/material.dart';

class Categoria {
  final int id;
  final String nombre;
  final int? parentId;

  Categoria({required this.id, required this.nombre, this.parentId});
}

String emojiCategoria(String nombre) {
  switch (nombre) {
    case 'Operación principal':
      return '🏨';
    case 'Servicios complementarios':
      return '🧺';
    case 'Eventos y alquileres':
      return '🎉';
    case 'Personal':
      return '👨‍💼';
    case 'Servicios básicos':
      return '⚡';
    case 'Mantenimiento':
      return '🔧';
    case 'Otros':
      return '➕';
    default:
      return '';
  }
}

class CategoriaTreeSelect extends StatefulWidget {
  final List<Categoria> categorias;
  final Function(Categoria) onSelected;

  const CategoriaTreeSelect({
    super.key,
    required this.categorias,
    required this.onSelected,
  });

  @override
  State<CategoriaTreeSelect> createState() => _CategoriaTreeSelectState();
}

class _CategoriaTreeSelectState extends State<CategoriaTreeSelect> {
  late Map<int?, List<Categoria>> mapa;
  List<Categoria> seleccion = [];

  @override
  void initState() {
    super.initState();

    mapa = {};
    for (var c in widget.categorias) {
      mapa.putIfAbsent(c.parentId, () => []).add(c);
    }
  }

  void seleccionarNivel(int nivel, Categoria cat) {
    setState(() {
      if (seleccion.length > nivel) {
        seleccion = seleccion.sublist(0, nivel);
      }
      seleccion.add(cat);
    });

    // si no tiene hijos → es hoja → seleccionar
    if (!(mapa.containsKey(cat.id))) {
      widget.onSelected(cat);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dropdowns = [];

    int? parentId;

    for (int i = 0; ; i++) {
      final opciones = mapa[parentId];
      if (opciones == null) break;

      final seleccionado = i < seleccion.length ? seleccion[i] : null;

      dropdowns.add(
        DropdownButton<Categoria>(
          hint: Text('Seleccionar Categoria'),
          value: seleccionado,
          items: opciones.map((c) {
            final esRaiz = c.parentId == null;
            final label = esRaiz
                ? '${emojiCategoria(c.nombre)} ${c.nombre}'
                : c.nombre;

            return DropdownMenuItem(value: c, child: Text(label));
          }).toList(),
          onChanged: (value) {
            if (value != null) seleccionarNivel(i, value);
          },
        ),
      );

      if (seleccionado == null) break;
      parentId = seleccionado.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dropdowns,
    );
  }
}
