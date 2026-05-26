import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_model.dart';
import '../../../../../../main.dart';
import 'dart:typed_data';

class UsuarioRepository {
  final SupabaseClient _client;

  UsuarioRepository({SupabaseClient? client}) : _client = client ?? supabase;

  // ── Obtener perfil del usuario actual ─────────────────────────────
  Future<UsuarioModel?> obtenerPerfil() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _client.from('usuarios').select().eq('id', userId).maybeSingle();

    if (response == null) return null;
    return UsuarioModel.fromJson(response);
  }

  // ── Actualizar nombre y avatar del perfil ─────────────────────────
  Future<UsuarioModel> actualizarPerfil({
    required String nombre,
    String? avatarUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('usuarios')
        .update({
          'nombre': nombre,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        })
        .eq('id', userId)
        .select()
        .single();

    return UsuarioModel.fromJson(response);
  }

  // ── Subir foto de avatar a Storage ───────────────────────────────
  Future<String> subirAvatar(Uint8List bytes, String extension) async {
    final userId = _client.auth.currentUser!.id;
    final storagePath = '$userId/avatar.$extension';

    await _client.storage.from('fotos_viaje').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true, // Sobreescribe el avatar anterior
          ),
        );

    return _client.storage.from('fotos_viaje').getPublicUrl(storagePath);
  }

  // ── Estadísticas del usuario ──────────────────────────────────────
  Future<Map<String, int>> obtenerEstadisticas() async {
    final userId = _client.auth.currentUser!.id;

    // Total de entradas
    final entradasResp =
        await _client.from('entradas_viaje').select('id').eq('user_id', userId);

    // Total de fotos
    final fotosResp = await _client
        .from('fotos')
        .select('id, entradas_viaje!inner(user_id)')
        .eq('entradas_viaje.user_id', userId);

    return {
      'entradas': (entradasResp as List).length,
      'fotos': (fotosResp as List).length,
    };
  }
}
