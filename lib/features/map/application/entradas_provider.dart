import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/entrada_viaje_model.dart';
import '../data/models/foto_model.dart';
import '../data/repositories/entrada_viaje_repository.dart';

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

class EntradasNotifier extends StateNotifier<EntradasState> {
  final EntradaViajeRepository _repository;

  EntradasNotifier(this._repository) : super(const EntradasState());

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
      final nueva = await _repository.crearEntrada(
        titulo: titulo,
        nota: nota,
        latitud: latitud,
        longitud: longitud,
        fechaVisita: fechaVisita,
      );

      final fotosSubidas = <FotoModel>[];
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
        fotosSubidas.add(fotoModel);
      }

      final entradaCompleta = nueva.copyWith(fotos: fotosSubidas);
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

  Future<bool> editarEntradaCompleta({
    required EntradaViaje entrada,
    required List<FotoModel> fotosAEliminar,
    required List<({Uint8List bytes, String extension})> fotosNuevas,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.actualizarEntrada(entrada);

      for (final foto in fotosAEliminar) {
        await _repository.eliminarFoto(foto);
      }

      final fotosRestantes = entrada.fotos
          .where((f) => !fotosAEliminar.any((d) => d.id == f.id))
          .length;

      for (int i = 0; i < fotosNuevas.length; i++) {
        final foto = fotosNuevas[i];
        await _repository.subirFoto(
          entradaId: entrada.id,
          rutaLocal: '',
          bytes: foto.bytes,
          extension: foto.extension,
          esPrincipal: fotosRestantes == 0 && i == 0,
          orden: fotosRestantes + i,
        );
      }

      final actualizada = await _repository.obtenerEntradaPorId(entrada.id);
      if (actualizada != null) {
        state = state.copyWith(
          entradas: state.entradas
              .map((e) => e.id == actualizada.id ? actualizada : e)
              .toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      debugPrint('error editando entrada: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Error al actualizar.');
      return false;
    }
  }

  List<EntradaViaje> buscar(String query) {
    if (query.trim().isEmpty) return state.entradas;
    final q = query.toLowerCase();
    return state.entradas
        .where((e) =>
            e.titulo.toLowerCase().contains(q) ||
            e.nota.toLowerCase().contains(q))
        .toList();
  }

  void limpiarError() => state = state.copyWith(errorMessage: null);
}

final entradaViajeRepositoryProvider =
    Provider<EntradaViajeRepository>((ref) => EntradaViajeRepository());

final entradasNotifierProvider =
    StateNotifierProvider<EntradasNotifier, EntradasState>((ref) {
  final repo = ref.watch(entradaViajeRepositoryProvider);
  return EntradasNotifier(repo);
});

final entradasProvider = Provider<List<EntradaViaje>>((ref) {
  return ref.watch(entradasNotifierProvider).entradas;
});
