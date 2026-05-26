import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'map_widget_stub.dart' if (dart.library.html) 'map_widget_web.dart';

import '../../../../core/router/app_router.dart';
import '../../application/entradas_provider.dart';
import '../../data/models/entrada_viaje_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(entradasNotifierProvider.notifier).cargarEntradas());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(entradasNotifierProvider);
    final entradas = state.entradas.where((e) => e.tieneUbicacion).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis viajes'),
      ),
      body: Stack(
        children: [
          // mapita
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            buildMapView(entradas),

          // panel inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text('Lugares registrados',
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '${entradas.length} en el mapa',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (entradas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      child: Text(
                        'Aún no tienes lugares. ¡Toca + para agregar el primero!',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: entradas.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final e = entradas[i];
                          final color =
                              Colors.primaries[i % Colors.primaries.length];
                          return _MiniCard(entry: e, color: color);
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('${AppRoutes.map}/new-entry');
          if (mounted) {
            ref.read(entradasNotifierProvider.notifier).cargarEntradas();
            setState(() {});
          }
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nuevo lugar'),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final EntradaViaje entry;
  final Color color;
  const _MiniCard({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.gallery}/${entry.id}'),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(entry.titulo,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.latitud!.toStringAsFixed(3)}°, ${entry.longitud!.toStringAsFixed(3)}°',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '${entry.fechaVisita.day}/${entry.fechaVisita.month}/${entry.fechaVisita.year}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
