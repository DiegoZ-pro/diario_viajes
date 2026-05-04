import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../application/entradas_provider.dart';
import '../../data/models/entrada_viaje_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  final LatLng _initialCenter = LatLng(-17.3895, -66.1568);
  static const double _initialZoom = 5.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(entradasNotifierProvider.notifier).cargarEntradas());
  }

  void _flyTo(LatLng point) {
    _mapController.move(point, 13.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final state    = ref.watch(entradasNotifierProvider);
    final entradas = state.entradas
        .where((e) => e.tieneUbicacion)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis viajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Centrar mapa',
            onPressed: () =>
                _mapController.move(_initialCenter, _initialZoom),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Mapa OpenStreetMap ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom:   _initialZoom,
              minZoom: 2.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.diario_viajes',
                maxZoom: 18,
              ),
              if (!state.isLoading)
                MarkerLayer(
                  markers: entradas.asMap().entries.map((entry) {
                    final i     = entry.key;
                    final e     = entry.value;
                    final color =
                        Colors.primaries[i % Colors.primaries.length];
                    final point = LatLng(e.latitud!, e.longitud!);

                    return Marker(
                      point:  point,
                      width:  140,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          _flyTo(point);
                          _showEntryCard(context, e, color);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                e.titulo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(12, 7),
                              painter: _ArrowPainter(color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          if (state.isLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Panel inferior ──────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow
                        .withValues(alpha: 0.10),
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
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text('Lugares registrados',
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '${entradas.length} en el mapa',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme
                                  .colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    )
                  else if (entradas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: Text(
                        'Aún no tienes lugares. ¡Toca + para agregar el primero!',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme
                                .colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: entradas.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final e = entradas[i];
                          final color = Colors.primaries[
                              i % Colors.primaries.length];
                          return _MiniCard(
                            entry: e,
                            color: color,
                            onTap: () => _flyTo(
                                LatLng(e.latitud!, e.longitud!)),
                          );
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
            ref
                .read(entradasNotifierProvider.notifier)
                .cargarEntradas();
          }
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nuevo lugar'),
      ),
    );
  }

  void _showEntryCard(
      BuildContext context, EntradaViaje entry, Color color) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.fotoPrincipal != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  entry.fotoPrincipal!.url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: color.withValues(alpha: 0.15),
                    child: Icon(Icons.image,
                        size: 56,
                        color: color.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.location_on, color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(entry.titulo,
                        style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.latitud!.toStringAsFixed(5)}°, '
              '${entry.longitud!.toStringAsFixed(5)}°',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            if (entry.nota.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.nota,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                          '${AppRoutes.gallery}/${entry.id}');
                    },
                    child: const Text('Ver detalle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final EntradaViaje entry;
  final Color color;
  final VoidCallback onTap;

  const _MiniCard({
    required this.entry,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: theme.colorScheme.outlineVariant),
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
              '${entry.latitud!.toStringAsFixed(3)}°, '
              '${entry.longitud!.toStringAsFixed(3)}°',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '${entry.fechaVisita.day}/${entry.fechaVisita.month}/${entry.fechaVisita.year}',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}