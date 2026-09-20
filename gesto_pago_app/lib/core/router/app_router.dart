import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/catalogo/presentation/inicio_screen.dart';
import '../../features/pagos/presentation/comprobante_screen.dart';
import '../../features/pagos/presentation/historial_screen.dart';
import '../../features/pagos/presentation/pago_screen.dart';
import '../../features/persona/presentation/perfil_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifica al router cuando cambia el estado de sesión para re-evaluar redirecciones.
class _AuthRouterListenable extends ChangeNotifier {
  _AuthRouterListenable(Ref ref) {
    ref.listen<SessionState>(
      sessionControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthRouterListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final status = ref.read(sessionControllerProvider).status;
      final loc = state.matchedLocation;
      final enAuth = loc == '/login' || loc == '/register';
      switch (status) {
        case SessionStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case SessionStatus.unauthenticated:
          return enAuth ? null : '/login';
        case SessionStatus.authenticated:
          return (enAuth || loc == '/splash') ? '/home' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const InicioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/historial',
                builder: (_, _) => const HistorialScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (_, _) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/pago/:idServicio/:idProducto',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idServicio = int.parse(state.pathParameters['idServicio']!);
          final idProducto = int.parse(state.pathParameters['idProducto']!);
          return PagoScreen(idServicio: idServicio, idProducto: idProducto);
        },
      ),
      GoRoute(
        path: '/comprobante/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ComprobanteScreen(
          transaccionId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});

/// Cascarón con barra de navegación inferior para las tres secciones principales.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.localeOf(context);
    final es = l10n.languageCode == 'es';
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: es ? 'Inicio' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: es ? 'Historial' : 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: es ? 'Perfil' : 'Profile',
          ),
        ],
      ),
    );
  }
}