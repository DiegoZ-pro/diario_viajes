import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart';

// ── Estado de autenticación ───────────────────────────────────────────
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

// ── Notifier ──────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.loading()) {
    _init();
  }

  void _init() {
    // Sesión actual al arrancar la app
    final session = supabase.auth.currentSession;
    if (session != null) {
      state = AuthState.authenticated(session.user);
    } else {
      state = const AuthState.unauthenticated();
    }

    // Escuchar cambios de sesión en tiempo real
    supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  // ── Registro con email y contraseña ──────────────────────────────
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
      // El trigger handle_new_user() crea el perfil automáticamente
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: _traducirError(e.message));
    } catch (e) {
      state = const AuthState.unauthenticated(
          error: 'Error inesperado. Intenta de nuevo.');
    }
  }

  // ── Inicio de sesión con email y contraseña ───────────────────────
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

  // ── Inicio de sesión con Google ───────────────────────────────────
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

  // ── Cerrar sesión ────────────────────────────────────────────────
  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AuthState.unauthenticated();
  }

  // ── Traducir errores de Supabase al español ───────────────────────
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

// ── Providers ─────────────────────────────────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// Acceso directo al usuario actual
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

// ¿Está autenticado?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
