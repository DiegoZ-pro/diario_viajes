import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/map/presentation/screens/new_entry_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screens.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

// ── Nombres de rutas ──────────────────────────────────────────────────
class AppRoutes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const map = '/map';
  static const gallery = '/gallery';
  static const profile = '/profile';
}

// ── Provider del router ───────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  // Escuchar cambios en el estado de autenticación
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authNotifierProvider.notifier).stream,
    ),

    // ── Redirección basada en sesión real ─────────────────────────
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;

      // Mientras carga no redirigir
      if (isLoading) return null;

      final isAuthRoute = location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.register;

      // Si está autenticado y en pantalla de auth → ir al mapa
      if (isAuthenticated && isAuthRoute) return AppRoutes.map;

      // Si no está autenticado y en ruta protegida → ir a bienvenida
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.welcome;

      return null;
    },

    routes: [
      // ── Auth ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Shell con NavigationBar ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNavBar(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (_, __) => const MapScreen(),
              routes: [
                GoRoute(
                  path: 'new-entry',
                  builder: (_, __) => const NewEntryScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.gallery,
              builder: (_, __) => const GalleryScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => EntryDetailScreen(
                    entryId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Página no encontrada: ${state.uri}')),
    ),
  );
});

// ── Shell widget ──────────────────────────────────────────────────────
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa'),
          NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library),
              label: 'Galería'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

// ── Helper para que GoRouter escuche streams de Riverpod ─────────────
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
