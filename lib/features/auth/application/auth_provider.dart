import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.authenticated(User this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  const AuthState.unauthenticated({String? error})
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = error;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.loading()) {
    _init();
  }

  void _init() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      state = AuthState.authenticated(session.user);
    } else {
      state = const AuthState.unauthenticated();
    }

    supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  Future<void> signUp({
    required String nombre,
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': nombre},
      );
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: _traducirError(e.message));
    } catch (e) {
      state = const AuthState.unauthenticated(
          error: 'Error inesperado. Intenta de nuevo.');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: _traducirError(e.message));
    } catch (e) {
      state = const AuthState.unauthenticated(
          error: 'Error inesperado. Intenta de nuevo.');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.traveldiario://login-callback',
      );
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: _traducirError(e.message));
    } catch (e) {
      state = const AuthState.unauthenticated(
          error: 'Error con Google. Intenta de nuevo.');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AuthState.unauthenticated();
  }

  String _traducirError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Este correo ya está registrado.';
    }
    if (msg.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (msg.contains('unable to validate email')) {
      return 'Correo electrónico inválido.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }
    return message;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});
