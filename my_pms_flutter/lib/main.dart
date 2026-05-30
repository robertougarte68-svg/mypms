import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_pms/providers/global_provider.dart';
import 'package:my_pms/providers/socket_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:my_pms/data/go_route.dart'; //router
import 'package:my_pms/presentation/themes/app_dark_theme.dart';
import 'package:my_pms/presentation/themes/app_light_theme.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/providers/hotel_provider.dart';
import 'package:my_pms/providers/user_provider.dart';
import 'package:bot_toast/bot_toast.dart';
//PROVIDERS
import 'package:provider/provider.dart';
import 'package:my_pms/providers/room_provider.dart';
import 'package:my_pms/providers/client_provider.dart';

void main() async {
  // runApp(const Pruebas());
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions options = WindowOptions(minimumSize: Size(800, 500));

    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => GlobalProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()..connect()),
      ],
      child: Consumer<GlobalProvider>(
        builder: (context, globalProvider, child) {
          return MaterialApp.router(
            builder: BotToastInit(),

            routerConfig: router,
            title: 'pms_hotelero',
            theme: AppLightTheme.theme,
            darkTheme: AppDarkTheme.theme,
            themeMode: globalProvider.themeMode, //light or dark
          );
        },
      ),
    );
  }
}
