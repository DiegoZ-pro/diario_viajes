// Constantes globales de la aplicación

class AppConstants {
  // ── Supabase ───────────────────────────────────────────────────────
  // Nombres de tablas
  static const String tableUsers = 'usuarios';
  static const String tableEntries = 'entradas_viaje';
  static const String tablePhotos = 'fotos';

  // Nombre del bucket de Storage
  static const String storageBucket = 'fotos_viaje';

  // ── Hive ───────────────────────────────────────────────────────────
  // Nombres de cajas (boxes) para caché local
  static const String hiveBoxEntries = 'entries_cache';
  static const String hiveBoxSettings = 'settings';

  // ── UI ─────────────────────────────────────────────────────────────
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // ── Imágenes ───────────────────────────────────────────────────────
  // Calidad de compresión al subir fotos (0-100)
  static const int imageQuality = 80;
  // Tamaño máximo de imagen en píxeles
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1920;
}
