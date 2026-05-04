class UsuarioModel {
  final String id;
  final String nombre;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) => UsuarioModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'avatar_url': avatarUrl,
      };

  UsuarioModel copyWith({String? nombre, String? avatarUrl}) => UsuarioModel(
        id: id,
        nombre: nombre ?? this.nombre,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  // Iniciales para mostrar en avatar cuando no hay foto
  String get iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UsuarioModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
