import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// importación condicional del selector de ubicación
import 'location_picker_stub.dart'
    if (dart.library.html) 'location_picker_web.dart';

import '../../application/entradas_provider.dart';

class NewEntryScreen extends ConsumerStatefulWidget {
  const NewEntryScreen({super.key});

  @override
  ConsumerState<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends ConsumerState<NewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  double? _latitud;
  double? _longitud;
  bool _detectandoGPS = false;
  bool _guardando = false;

  final List<({Uint8List bytes, String extension, String nombre})> _fotos = [];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // gps
  Future<void> _detectarUbicacion() async {
    setState(() => _detectandoGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Activa el servicio de ubicación en tu dispositivo.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Permisos de ubicación denegados permanentemente. Actívalos en Ajustes.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectandoGPS = false);
    }
  }

  // selector de mapa
  Future<void> _abrirSelectorMapa() async {
    final result = await showLocationPicker(context);
    if (result != null && mounted) {
      setState(() {
        _latitud = result['lat'];
        _longitud = result['lng'];
      });
    }
  }

  // fotos
  Future<void> _agregarFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final extension = picked.name.split('.').last.toLowerCase();
      setState(() => _fotos
          .add((bytes: bytes, extension: extension, nombre: picked.name)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar la foto.')),
        );
      }
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _agregarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _agregarFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // guardar
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ubicación.')),
      );
      return;
    }

    setState(() => _guardando = true);

    final fotosParaSubir =
        _fotos.map((f) => (bytes: f.bytes, extension: f.extension)).toList();

    final exito =
        await ref.read(entradasNotifierProvider.notifier).crearEntrada(
              titulo: _titleController.text.trim(),
              nota: _noteController.text.trim(),
              latitud: _latitud!,
              longitud: _longitud!,
              fechaVisita: DateTime.now(),
              fotos: fotosParaSubir,
            );

    if (mounted) {
      setState(() => _guardando = false);
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lugar guardado exitosamente')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo lugar'),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // titulo
            const _StepLabel(number: '1', label: 'Nombre del lugar'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ej: Coliseo Romano, Playa del Carmen...',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa el nombre del lugar'
                  : null,
            ),

            const SizedBox(height: 28),

            // fotos
            const _StepLabel(number: '2', label: 'Fotografías'),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _mostrarOpcionesFoto,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: theme.colorScheme.primary),
                          const SizedBox(height: 4),
                          Text('Agregar',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ..._fotos.asMap().entries.map((e) {
                    final i = e.key;
                    final foto = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(foto.bytes,
                                width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          if (i == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Portada',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _fotos.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // nota
            const _StepLabel(number: '3', label: 'Nota personal'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '¿Cómo fue tu experiencia?',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.edit_note_outlined),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ubicación
            const _StepLabel(number: '4', label: 'Ubicación'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  // Indicador de ubicación actual
                  Container(
                    height: 70,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _detectandoGPS
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Obteniendo ubicación...'),
                              ],
                            )
                          : _latitud != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                    const SizedBox(width: 6),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_latitud!.toStringAsFixed(5)}°',
                                          style: theme.textTheme.labelMedium,
                                        ),
                                        Text(
                                          '${_longitud!.toStringAsFixed(5)}°',
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 18),
                                  ],
                                )
                              : Text(
                                  'Sin ubicación seleccionada',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botones de ubicación
                  Row(
                    children: [
                      // GPS
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Usar GPS'),
                          onPressed: _detectandoGPS ? null : _detectarUbicacion,
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Seleccionar en mapa
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('En el mapa'),
                          onPressed: _abrirSelectorMapa,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 46)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // boton guardar
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save_outlined),
              label: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar lugar'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: theme.colorScheme.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
