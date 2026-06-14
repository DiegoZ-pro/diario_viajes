import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entrada_viaje_model.dart';
import '../models/foto_model.dart';

class EntradaViajeRepository {
  final SupabaseClient _client;

  EntradaViajeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<EntradaViaje>> obtenerEntradas() async {
    final response = await _client
        .from('entradas_viaje')
        .select('*, fotos(*)')
        .order('fecha_visita', ascending: false);

    return (response as List)
        .map((json) => EntradaViaje.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<EntradaViaje?> obtenerEntradaPorId(String id) async {
    final response = await _client
        .from('entradas_viaje')
        .select('*, fotos(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return EntradaViaje.fromJson(response);
  }

  Future<EntradaViaje> crearEntrada({
    required String titulo,
    required String nota,
    required double latitud,
    required double longitud,
    required DateTime fechaVisita,
    bool esPublica = false,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('entradas_viaje')
        .insert({
          'user_id': userId,
          'titulo': titulo,
          'nota': nota,
          'latitud': latitud,
          'longitud': longitud,
          'fecha_visita': fechaVisita.toIso8601String().split('T').first,
          'es_publica': esPublica,
        })
        .select('*, fotos(*)')
        .single();

    return EntradaViaje.fromJson(response);
  }

  Future<EntradaViaje> actualizarEntrada(EntradaViaje entrada) async {
    final response = await _client
        .from('entradas_viaje')
        .update(entrada.toJson())
        .eq('id', entrada.id)
        .select('*, fotos(*)')
        .single();

    return EntradaViaje.fromJson(response);
  }

  Future<void> eliminarEntrada(String id) async {
    await _client.from('entradas_viaje').delete().eq('id', id);
  }

  Future<FotoModel> subirFoto({
    required String entradaId,
    required String rutaLocal,
    required Uint8List bytes,
    required String extension,
    bool esPrincipal = false,
    int orden = 0,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = '$userId/$entradaId/$fileName';

    await _client.storage.from('fotos_viaje').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: false,
          ),
        );

    final url = _client.storage.from('fotos_viaje').getPublicUrl(storagePath);

    final response = await _client
        .from('fotos')
        .insert({
          'entrada_id': entradaId,
          'url': url,
          'storage_path': storagePath,
          'es_principal': esPrincipal,
          'orden': orden,
        })
        .select()
        .single();

    return FotoModel.fromJson(response);
  }

  Future<void> eliminarFoto(FotoModel foto) async {
    await _client.storage.from('fotos_viaje').remove([foto.storagePath]);
    await _client.from('fotos').delete().eq('id', foto.id);
  }
}
