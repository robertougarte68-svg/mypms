import 'package:bot_toast/bot_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pms/presentation/auth/create_hotel_screen.dart';
import 'package:my_pms/presentation/auth/hotel_selector_screen.dart';
import 'package:my_pms/presentation/auth/join_hotel_screen.dart';
import 'package:my_pms/presentation/auth/login_screen.dart';
import 'package:my_pms/presentation/auth/register_screen.dart';
import 'package:my_pms/presentation/screens/homepage.dart';
import 'package:my_pms/presentation/screens/rooms_panel.dart';
import 'package:my_pms/providers/auth_provider.dart';
import 'package:my_pms/utils/vista_pdf_page.dart';
import 'package:provider/provider.dart';

final GoRouter router = GoRouter(
  observers: [BotToastNavigatorObserver()],
  initialLocation: '/homepage', //TODO: cambiar a '/login' para produccion
  debugLogDiagnostics: true,
  //TODO descomentar para prodiccion
  // redirect: (context, state) {
  //   final authProv = context.read<AuthProvider>();
  //   bool loggedIn = authProv.isLogged;

  //   if (!loggedIn &&
  //       state.uri.path != '/login' &&
  //       state.uri.path != '/register') {
  //     return '/login';
  //   }
  //   if (loggedIn &&
  //       authProv.userRol == null &&
  //       state.uri.path != '/createHotel' &&
  //       state.uri.path != '/joinHotel' &&
  //       state.uri.path != '/selector') {
  //     return '/selector';
  //   }

  //   return null;
  // },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/createHotel',
      builder: (context, state) => const CreateHotelScreen(),
    ),
    GoRoute(
      path: '/joinHotel',
      builder: (context, state) => const JoinHotelScreen(),
    ),
    GoRoute(
      path: '/selector',
      builder: (context, state) => const HotelSelectorScreen(),
    ),
    GoRoute(path: '/roomsPanel', builder: (context, state) => RoomsPanel()),
    GoRoute(path: '/homepage', builder: (context, state) => MyHomePage()),
    GoRoute(
      path: '/printView',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return VistaPdfPage(data: data);
      },
    ),
    GoRoute(
      path: '/check',
      builder: (context, state) {
        // Lógica de redirección
        // if (!LocalDB.user['isLogged']) return const LoginScreen();
        // if (LocalDB.user['hotelId'] == null)
        //   return const CreateHotelScreen(); // o JoinHotelScreen

        return MyHomePage(); //TODO
      },
    ),
  ],
);
