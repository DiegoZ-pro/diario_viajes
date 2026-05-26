// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../../data/models/entrada_viaje_model.dart';

int _mapViewCounter = 0;

Widget buildMapView(List<EntradaViaje> entradas) {
  return _WebMapView(entradas: entradas);
}

class _WebMapView extends StatefulWidget {
  final List<EntradaViaje> entradas;
  const _WebMapView({required this.entradas});

  @override
  State<_WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends State<_WebMapView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _mapViewCounter++;
    _viewType = 'leaflet-map-$_mapViewCounter';
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
          ..srcdoc = _buildMapHtml();
        return iframe;
      },
    );
  }

  String _buildMapHtml() => '''
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
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    var map = L.map('map').setView([-17.3895, -66.1568], 13);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18, attribution: '© OpenStreetMap'
    }).addTo(map);

    var blueDot        = null;
    var accuracyCircle = null;

    if (navigator.geolocation) {
      navigator.geolocation.watchPosition(function(pos) {
        var latlng = [pos.coords.latitude, pos.coords.longitude];

        if (blueDot)        { map.removeLayer(blueDot); }
        if (accuracyCircle) { map.removeLayer(accuracyCircle); }

        accuracyCircle = L.circle(latlng, {
          radius: pos.coords.accuracy,
          color: '#4285F4',
          fillColor: '#4285F4',
          fillOpacity: 0.1,
          weight: 1
        }).addTo(map);

        blueDot = L.circleMarker(latlng, {
          radius: 10,
          fillColor: '#4285F4',
          color: 'white',
          weight: 3,
          opacity: 1,
          fillOpacity: 1
        }).addTo(map);

        map.setView(latlng, 15);
      }, function() {}, { enableHighAccuracy: true });
    }
  </script>
</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
