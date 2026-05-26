import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Muestra un mapa interactivo para elegir ubicación
// Retorna {lat, lng} o null si se cancela
Future<Map<String, double>?> showLocationPicker(BuildContext context) {
  return showModalBottomSheet<Map<String, double>?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _MobileLocationPicker(),
  );
}

class _MobileLocationPicker extends StatefulWidget {
  const _MobileLocationPicker();

  @override
  State<_MobileLocationPicker> createState() => _MobileLocationPickerState();
}

class _MobileLocationPickerState extends State<_MobileLocationPicker> {
  late final WebViewController _controller;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LocationPicker',
        onMessageReceived: (msg) {
          final parts = msg.message.split(',');
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
        },
      )
      ..loadHtmlString(_pickerHtml());
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

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(pos) {
        map.setView([pos.coords.latitude, pos.coords.longitude], 14);
      });
    }

    map.on('click', function(e) {
      var lat = e.latlng.lat.toFixed(7);
      var lng = e.latlng.lng.toFixed(7);

      if (marker) { map.removeLayer(marker); }
      marker = L.marker([lat, lng]).addTo(map)
        .bindPopup('Ubicación seleccionada').openPopup();

      document.getElementById('hint').style.display = 'none';

      // Enviar al canal de Flutter (iOS/Android)
      LocationPicker.postMessage(lat + ',' + lng);
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ),
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
