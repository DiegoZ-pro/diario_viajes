// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

// Muestra un mapa interactivo para elegir ubicación
// Retorna {lat, lng} o null si se cancela
Future<Map<String, double>?> showLocationPicker(BuildContext context) {
  return showModalBottomSheet<Map<String, double>?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _WebLocationPicker(),
  );
}

class _WebLocationPicker extends StatefulWidget {
  const _WebLocationPicker();

  @override
  State<_WebLocationPicker> createState() => _WebLocationPickerState();
}

class _WebLocationPickerState extends State<_WebLocationPicker> {
  static int _counter = 0;
  late final String _viewType;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _counter++;
    _viewType = 'location-picker-$_counter';
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..srcdoc = _pickerHtml();
        return iframe;
      },
    );

    // Escuchar coordenadas enviadas desde el iframe
    html.window.onMessage.listen((event) {
      final data = event.data?.toString() ?? '';
      if (data.startsWith('loc:')) {
        final parts = data.replaceFirst('loc:', '').split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null && mounted) {
            setState(() {
              _selectedLat = lat;
              _selectedLng = lng;
            });
          }
        }
      }
    });
  }

  String _pickerHtml() => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css"/>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    html, body, #map { width:100%; height:100%; }
    #hint {
      position:absolute; top:10px; left:50%; transform:translateX(-50%);
      background:rgba(0,0,0,0.6); color:white; padding:6px 14px;
      border-radius:20px; font-size:13px; z-index:1000; pointer-events:none;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <div id="hint">Toca el mapa para seleccionar una ubicación</div>
  <script>
    var map = L.map('map').setView([-17.3895, -66.1568], 5);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom:18, attribution:'© OpenStreetMap'
    }).addTo(map);

    var marker = null;

    // Auto-zoom a ubicación del usuario
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(pos) {
        map.setView([pos.coords.latitude, pos.coords.longitude], 14);
      });
    }

    // Click en el mapa → colocar marcador y enviar coordenadas
    map.on('click', function(e) {
      var lat = e.latlng.lat.toFixed(7);
      var lng = e.latlng.lng.toFixed(7);

      if (marker) { map.removeLayer(marker); }
      marker = L.marker([lat, lng]).addTo(map)
        .bindPopup('Ubicación seleccionada').openPopup();

      document.getElementById('hint').style.display = 'none';

      // Enviar coordenadas al Flutter parent
      window.parent.postMessage('loc:' + lat + ',' + lng, '*');
    });
  </script>
</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Seleccionar ubicación',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: HtmlElementView(viewType: _viewType),
              ),
            ),
          ),

          // Coordenadas seleccionadas
          if (_selectedLat != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedLat!.toStringAsFixed(5)}°, ${_selectedLng!.toStringAsFixed(5)}°',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Toca el mapa para seleccionar',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),

          // Botón confirmar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: _selectedLat == null
                  ? null
                  : () => Navigator.pop(context, {
                        'lat': _selectedLat!,
                        'lng': _selectedLng!,
                      }),
              child: const Text('Confirmar ubicación'),
            ),
          ),
        ],
      ),
    );
  }
}
