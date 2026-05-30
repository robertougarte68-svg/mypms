import 'package:flutter/material.dart';

/// Barra reutilizable para filtros/opciones.
/// Usa automáticamente los colores del Theme.
///
/// Ejemplo:
/// ReusableMenuBar(
///   items: [
///     MenuItemData(icon: Icons.list, label: "Todos"),
///     MenuItemData(icon: Icons.star, label: "Favoritos"),
///     MenuItemData(icon: Icons.settings, label: "Config"),
///   ],
///   selectedIndex: selected,
///   onSelected: (i) {
///     setState(() => selected = i);
///   },
/// )

class MenuItemData {
  final IconData icon;
  final String label;

  MenuItemData({required this.icon, required this.label});
}

class MyMenuBar extends StatelessWidget {
  final List<MenuItemData> items;
  final int selectedIndex;
  final Function(int) onSelected;
  final List<Widget>? others;

  const MyMenuBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.others,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        // border: BoxBorder.all(width: 1),
        color: colorScheme.surfaceContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  onSelected(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  // margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.surfaceContainerHighest
                        : Colors.transparent,
                    // borderRadius: BorderRadius.circular(14),
                    // boxShadow: isSelected
                    //     ? [
                    //         BoxShadow(
                    //           color: colorScheme.shadow,
                    //           blurRadius: 5,
                    //           offset: const Offset(0, 5),
                    //         ),
                    //       ]
                    //     : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Expanded(child: SizedBox(width: 5)),
            ...others ?? [],
          ],
        ),
      ),
    );
  }
}
