// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
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
  static bool _viewRegistered = false;
  static const String _viewType = 'leaflet-map';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(entradasNotifierProvider.notifier).cargarEntradas());
  }

  // Genera el HTML completo con Leaflet y los marcadores
  String _buildMapHtml(List<EntradaViaje> entradas) {
    // Construir los marcadores JS
    final markersJs = entradas.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      if (!e.tieneUbicacion) return '';
      final colors = [
        'red', 'blue', 'green', 'orange', 'purple',
        'darkred', 'darkblue', 'darkgreen', 'cadetblue', 'darkpurple'
      ];
      final color = colors[i % colors.length];
      final titulo = e.titulo.replaceAll("'", "\\'");
      final nota   = e.nota.replaceAll("'", "\\'").replaceAll('\n', ' ');
      final fecha  = '${e.fechaVisita.day}/${e.fechaVisita.month}/${e.fechaVisita.year}';

      return '''
        L.marker([${e.latitud}, ${e.longitud}], {
          icon: L.icon({
            iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-$color.png',
            shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
            iconSize: [25, 41],
            iconAnchor: [12, 41],
            popupAnchor: [1, -34],
            shadowSize: [41, 41]
          })
        }).addTo(map).bindPopup(
          '<b>${titulo}</b><br/>' +
          '<small style="color:#666">$fecha</small><br/>' +
          '${nota.length > 80 ? nota.substring(0, 80) + '...' : nota}'
        );
      ''';
    }).join('\n');

    // Centro del mapa
    double centerLat = -17.3895;
    double centerLng = -66.1568;
    double zoom      = 5;

    if (entradas.isNotEmpty && entradas.first.tieneUbicacion) {
      centerLat = entradas.first.latitud!;
      centerLng = entradas.first.longitud!;
      zoom      = 8;
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css"/>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body, #map { width: 100%; height: 100%; }
    .leaflet-popup-content b { font-size: 14px; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    var map = L.map('map').setView([$centerLat, $centerLng], $zoom);

    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      attribution: '© OpenStreetMap contributors'
    }).addTo(map);

    $markersJs
  </script>
</body>
</html>
''';
  }

  void _registerView(List<EntradaViaje> entradas) {
    if (_viewRegistered) return;
    _viewRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.width  = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..srcdoc = _buildMapHtml(entradas);
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final state    = ref.watch(entradasNotifierProvider);
    final entradas = state.entradas
        .where((e) => e.tieneUbicacion)
        .toList();

    _registerView(entradas);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis viajes'),
      ),
      body: Stack(
        children: [
          // ── Mapa Leaflet via iframe ─────────────────────────────────
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            HtmlElementView(viewType: _viewType),

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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text('Lugares en el mapa',
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '${entradas.length} registrados',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Lista horizontal de mini-tarjetas
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final e = entradas[i];
                          final color = Colors.primaries[
                              i % Colors.primaries.length];
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
            _viewRegistered = false; // Fuerza recrear el mapa con nuevos marcadores
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

// ── Mini tarjeta ────────────────────────────────────────────────────
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