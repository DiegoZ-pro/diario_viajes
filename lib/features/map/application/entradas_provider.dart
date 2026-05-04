import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/entrada_viaje_model.dart';
import '../data/models/foto_model.dart';
import '../data/repositories/entrada_viaje_repository.dart';

// ── Estado ────────────────────────────────────────────────────────────
class EntradasState {
  final List<EntradaViaje> entradas;
  final bool isLoading;
  final String? errorMessage;

  const EntradasState({
    this.entradas = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EntradasState copyWith({
    List<EntradaViaje>? entradas,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EntradasState(
      entradas: entradas ?? this.entradas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────
class EntradasNotifier extends StateNotifier<EntradasState> {
  final EntradaViajeRepository _repository;

  EntradasNotifier(this._repository) : super(const EntradasState());

  // ── Cargar todas las entradas ─────────────────────────────────────
  Future<void> cargarEntradas() async {
    state = state.copyWith(isLoading: true);
    try {
      final entradas = await _repository.obtenerEntradas();
      state = state.copyWith(entradas: entradas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los viajes.',
      );
    }
  }

  // ── Crear nueva entrada con fotos opcionales ──────────────────────
  Future<bool> crearEntrada({
    required String titulo,
    required String nota,
    required double latitud,
    required double longitud,
    required DateTime fechaVisita,
    List<({Uint8List bytes, String extension})> fotos = const [],
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Crear la entrada en la BD
      final nueva = await _repository.crearEntrada(
        titulo: titulo,
        nota: nota,
        latitud: latitud,
        longitud: longitud,
        fechaVisita: fechaVisita,
      );

      // 2. Subir fotos si hay
      final fotasSubidas = <FotoModel>[];
      for (int i = 0; i < fotos.length; i++) {
        final foto = fotos[i];
        final fotoModel = await _repository.subirFoto(
          entradaId: nueva.id,
          rutaLocal: '',
          bytes: foto.bytes,
          extension: foto.extension,
          esPrincipal: i == 0,
          orden: i,
        );
        fotasSubidas.add(fotoModel);
      }

      // 3. Agregar al estado local
      final entradaCompleta = nueva.copyWith(fotos: fotasSubidas);
      state = state.copyWith(
        entradas: [entradaCompleta, ...state.entradas],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al guardar el lugar.',
      );
      return false;
    }
  }

  // ── Actualizar entrada existente ──────────────────────────────────
  Future<bool> actualizarEntrada(EntradaViaje entrada) async {
    try {
      final actualizada = await _repository.actualizarEntrada(entrada);
      state = state.copyWith(
        entradas: state.entradas
            .map((e) => e.id == actualizada.id ? actualizada : e)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar.');
      return false;
    }
  }

  // ── Eliminar entrada ──────────────────────────────────────────────
  Future<bool> eliminarEntrada(String id) async {
    try {
      await _repository.eliminarEntrada(id);
      state = state.copyWith(
        entradas: state.entradas.where((e) => e.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar.');
      return false;
    }
  }

  // ── Buscar por texto (filtro local) ───────────────────────────────
  List<EntradaViaje> buscar(String query) {
    if (query.trim().isEmpty) return state.entradas;
    final q = query.toLowerCase();
    return state.entradas
        .where((e) =>
            e.titulo.toLowerCase().contains(q) ||
            e.nota.toLowerCase().contains(q))
        .toList();
  }

  // ── Limpiar error ──────────────────────────────────────────────────
  void limpiarError() => state = state.copyWith(errorMessage: null);
}

// ── Providers ─────────────────────────────────────────────────────────
final entradaViajeRepositoryProvider =
    Provider<EntradaViajeRepository>((ref) => EntradaViajeRepository());

final entradasNotifierProvider =
    StateNotifierProvider<EntradasNotifier, EntradasState>((ref) {
  final repo = ref.watch(entradaViajeRepositoryProvider);
  return EntradasNotifier(repo);
});

// Acceso directo a la lista de entradas
final entradasProvider = Provider<List<EntradaViaje>>((ref) {
  return ref.watch(entradasNotifierProvider).entradas;
});
