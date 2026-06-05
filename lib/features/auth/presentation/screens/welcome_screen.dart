import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _featuresFade;
  late final Animation<Offset> _featuresSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(
            begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic)));

    _titleFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut));

    _featuresFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut));
    _featuresSlide = Tween<Offset>(
            begin: const Offset(0.12, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)));

    _buttonsFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _buttonsSlide = Tween<Offset>(
            begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.45, 1.0],
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.09),
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.travel_explore,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _titleFade,
                  child: Column(
                    children: [
                      Text(
                        'Diario de Viajes',
                        style: theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Registra, organiza y revive\ntus experiencias en el mapa',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SlideTransition(
                  position: _featuresSlide,
                  child: FadeTransition(
                    opacity: _featuresFade,
                    child: Column(
                      children: const [
                        _FeatureTile(
                          icon: Icons.map_outlined,
                          title: 'Mapa interactivo',
                          subtitle:
                              'Ve todos tus lugares visitados de un vistazo',
                        ),
                        SizedBox(height: 14),
                        _FeatureTile(
                          icon: Icons.photo_camera_outlined,
                          title: 'Fotos y notas',
                          subtitle:
                              'Captura el momento con fotos y descripciones',
                        ),
                        SizedBox(height: 14),
                        _FeatureTile(
                          icon: Icons.cloud_done_outlined,
                          title: 'Sincronizado en la nube',
                          subtitle:
                              'Tus recuerdos seguros y accesibles siempre',
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SlideTransition(
                  position: _buttonsSlide,
                  child: FadeTransition(
                    opacity: _buttonsFade,
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Iniciar sesión'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => context.go(AppRoutes.register),
                          child: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon,
              size: 22, color: theme.colorScheme.onSecondaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
