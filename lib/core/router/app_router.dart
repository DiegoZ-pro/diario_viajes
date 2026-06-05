import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/map/presentation/screens/new_entry_screen.dart';
import '../../features/map/presentation/screens/edit_entry_screen.dart';
import '../../features/map/presentation/screens/search_screen.dart';
import '../../features/map/data/models/entrada_viaje_model.dart';
import '../../features/gallery/presentation/screens/gallery_screens.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/stats_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

class AppRoutes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const map = '/map';
  static const gallery = '/gallery';
  static const profile = '/profile';
  static const search = '/search';
  static const settings = '/settings';
  static const profileEdit = '/profile/edit';
  static const profileChangePassword = '/profile/change-password';
  static const profileStats = '/profile/stats';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authNotifierProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;

      if (isLoading) return null;

      final isAuthRoute = location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.register;

      if (isAuthenticated && isAuthRoute) return AppRoutes.map;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.welcome;
      return null;
    },
    routes: [
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
      GoRoute(
        path: AppRoutes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
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
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, state) => EditEntryScreen(
                        entryId: state.pathParameters['id']!,
                        entry: state.extra as EntradaViaje?,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, __) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'change-password',
                  builder: (_, __) => const ChangePasswordScreen(),
                ),
                GoRoute(
                  path: 'stats',
                  builder: (_, __) => const StatsScreen(),
                ),
              ],
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

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
