import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TravelDiaryApp extends ConsumerWidget {
  const TravelDiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Diario de Viajes',
      debugShowCheckedModeBanner: false,

      // Tema claro y oscuro automático según el sistema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router declarativo con go_router
      routerConfig: router,
    );
  }
}
