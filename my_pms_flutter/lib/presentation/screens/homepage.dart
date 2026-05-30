import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/presentation/screens/taps/cuentas.dart';
import 'package:my_pms/presentation/screens/taps/dashboard.dart';
import 'package:my_pms/presentation/screens/taps/register.dart';
import 'package:my_pms/presentation/screens/taps/reservas.dart';
import 'package:my_pms/presentation/screens/taps/todaylist.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/global_provider.dart';
import 'package:provider/provider.dart';

class TabItem {
  final String title;
  final Widget page;
  final List<String> excludedRoles;

  TabItem({
    required this.title,
    required this.page,
    this.excludedRoles = const [],
  });
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final allTabs = [
    TabItem(title: "Dashboard", page: MyDashboard()),

    TabItem(
      title: "Register",
      page: MyRegister(),
      excludedRoles: ['housekeeping', 'administrador'],
    ),

    TabItem(
      title: "TodayList",
      page: TodayList(),
      excludedRoles: ['housekeeping', 'administrador'],
    ),

    TabItem(
      title: "Reservas",
      page: Reservas(),
      excludedRoles: ['housekeeping', 'administrador'],
    ),

    TabItem(title: "Cuentas", page: Cuentas(), excludedRoles: ['housekeeping']),
  ];
  final GlobalKey<ScaffoldState> llaveScaffold = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final globalProv = context.watch<GlobalProvider>();

    final visibleTabs = allTabs
        .where((tab) => !tab.excludedRoles.contains(authProv.userRol))
        .toList();
    return DefaultTabController(
      length: visibleTabs.length,
      child: Scaffold(
        key: llaveScaffold,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              llaveScaffold.currentState?.openDrawer();
            },
            icon: Icon(Icons.menu),
          ),
          title: Image.asset('assets/logotuku.jpg', height: 40),
          bottom: TabBar(
            tabs: visibleTabs.map((t) => Tab(text: t.title)).toList(),
          ),
        ),
        drawer: mydrawer(authProv, globalProv, context),

        body: TabBarView(children: visibleTabs.map((t) => t.page).toList()),
      ),
    );
  }

  Widget mydrawer(
    AuthProvider authProv,
    GlobalProvider globalProv,
    BuildContext context,
  ) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              authProv.isLogged ? authProv.username! : "Invitado",
            ),
            accountEmail: Text(
              authProv.isLogged ? "Usuario autenticado" : "No autenticado",
            ),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          //CAMBIAR TEMA
          ListTile(
            leading: Icon(
              globalProv.darkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text("Cambiar tema"),
            onTap: globalProv.toggleTheme,
          ),
          //LOG OUT
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              await authProv.logout();
              GoRouter.of(context).go('/login');
            },
          ),
          //GESTIONAR HABITACIONES
          ListTile(
            leading: const Icon(Icons.bed),
            title: const Text("Gestionar Habitaciones"),
            onTap: () async {
              GoRouter.of(context).push('/roomsPanel');
            },
          ),
        ],
      ),
    );
  }
}

class FormFields {
  int? number;
  String? descripcion;
  int? precio;
}
