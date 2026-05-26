import 'foto_model.dart';

class EntradaViaje {
  final String id;
  final String userId;
  final String titulo;
  final String nota;
  final double? latitud;
  final double? longitud;
  final DateTime fechaVisita;
  final bool esPublica;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Fotos relacionadas (cargadas con JOIN)
  final List<FotoModel> fotos;

  const EntradaViaje({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.nota,
    this.latitud,
    this.longitud,
    required this.fechaVisita,
    this.esPublica = false,
    required this.createdAt,
    required this.updatedAt,
    this.fotos = const [],
  });

  // Foto de portada (la marcada como principal, o la primera)
  FotoModel? get fotoPrincipal {
    if (fotos.isEmpty) return null;
    return fotos.firstWhere(
      (f) => f.esPrincipal,
      orElse: () => fotos.first,
    );
  }

  // Tiene coordenadas válidas para mostrar en el mapa
  bool get tieneUbicacion => latitud != null && longitud != null;

  // ── Serialización desde JSON (respuesta de Supabase) ───────────────
  factory EntradaViaje.fromJson(Map<String, dynamic> json) {
    final fotosJson = json['fotos'] as List<dynamic>? ?? [];
    return EntradaViaje(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titulo: json['titulo'] as String,
      nota: json['nota'] as String? ?? '',
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      fechaVisita: DateTime.parse(json['fecha_visita'] as String),
      esPublica: json['es_publica'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fotos: fotosJson
          .map((f) => FotoModel.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Serialización a JSON (para insertar/actualizar en Supabase) ────
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'titulo': titulo,
        'nota': nota,
        'latitud': latitud,
        'longitud': longitud,
        'fecha_visita': fechaVisita.toIso8601String().split('T').first,
        'es_publica': esPublica,
      };

  // ── CopyWith para actualizaciones parciales ────────────────────────
  EntradaViaje copyWith({
    String? titulo,
    String? nota,
    double? latitud,
    double? longitud,
    DateTime? fechaVisita,
    bool? esPublica,
    List<FotoModel>? fotos,
  }) {
    return EntradaViaje(
      id: id,
      userId: userId,
      titulo: titulo ?? this.titulo,
      nota: nota ?? this.nota,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaVisita: fechaVisita ?? this.fechaVisita,
      esPublica: esPublica ?? this.esPublica,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fotos: fotos ?? this.fotos,
    );
  }

  @override
  String toString() =>
      'EntradaViaje(id: $id, titulo: $titulo, fotos: ${fotos.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EntradaViaje && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
