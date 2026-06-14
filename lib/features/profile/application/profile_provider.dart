import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileState {
  final String nombre;
  final String? avatarUrl;
  final bool isLoading;

  const ProfileState({
    this.nombre = '',
    this.avatarUrl,
    this.isLoading = false,
  });

  ProfileState copyWith({String? nombre, String? avatarUrl, bool? isLoading}) {
    return ProfileState(
      nombre: nombre ?? this.nombre,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final SupabaseClient _client;

  ProfileNotifier(this._client) : super(const ProfileState());

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        state = state.copyWith(
          nombre: data['nombre'] as String? ?? '',
          avatarUrl: data['avatar_url'] as String?,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>((ref) {
  final notifier = ProfileNotifier(Supabase.instance.client);
  notifier.cargar();
  return notifier;
});
