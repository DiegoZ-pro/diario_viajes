import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entrada_viaje_model.dart';
import '../models/foto_model.dart';
import '../../../../../../main.dart';
import 'dart:typed_data';

class EntradaViajeRepository {
  final SupabaseClient _client;

  EntradaViajeRepository({SupabaseClient? client})
      : _client = client ?? supabase;

  // obtener todas las entradas del usuario con sus fotos
  Future<List<EntradaViaje>> obtenerEntradas() async {
    final response = await _client
        .from('entradas_viaje')
        .select('*, fotos(*)')
        .order('fecha_visita', ascending: false);

    return (response as List)
        .map((json) => EntradaViaje.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // obtener una entrada por ID
  Future<EntradaViaje?> obtenerEntradaPorId(String id) async {
    final response = await _client
        .from('entradas_viaje')
        .select('*, fotos(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return EntradaViaje.fromJson(response);
  }

  // nueva entrada
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

  // actualizar entrada existente
  Future<EntradaViaje> actualizarEntrada(EntradaViaje entrada) async {
    final response = await _client
        .from('entradas_viaje')
        .update(entrada.toJson())
        .eq('id', entrada.id)
        .select('*, fotos(*)')
        .single();

    return EntradaViaje.fromJson(response);
  }

  // eliminar entrada y fotos en cascada
  Future<void> eliminarEntrada(String id) async {
    await _client.from('entradas_viaje').delete().eq('id', id);
  }

  // buscar entrada por titulo
  Future<List<EntradaViaje>> buscarEntradas(String query) async {
    final response = await _client
        .from('entradas_viaje')
        .select('*, fotos(*)')
        .ilike('titulo', '%$query%')
        .order('fecha_visita', ascending: false);

    return (response as List)
        .map((json) => EntradaViaje.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // subir fotos a storage y registrar en tabla fotos
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

    // subir al bucket de Storage
    await _client.storage.from('fotos_viaje').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: false,
          ),
        );

    // obtener URL pública
    final url = _client.storage.from('fotos_viaje').getPublicUrl(storagePath);

    // registrar en la tabla fotos
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

  // eliminar foto de storage y tabla
  Future<void> eliminarFoto(FotoModel foto) async {
    // eliminar del Storage
    await _client.storage.from('fotos_viaje').remove([foto.storagePath]);

    // eliminar de la tabla
    await _client.from('fotos').delete().eq('id', foto.id);
  }
}
