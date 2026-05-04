class FotoModel {
  final String id;
  final String entradaId;
  final String url;
  final String storagePath;
  final bool esPrincipal;
  final int orden;
  final DateTime createdAt;

  const FotoModel({
    required this.id,
    required this.entradaId,
    required this.url,
    required this.storagePath,
    this.esPrincipal = false,
    this.orden = 0,
    required this.createdAt,
  });

  factory FotoModel.fromJson(Map<String, dynamic> json) => FotoModel(
        id: json['id'] as String,
        entradaId: json['entrada_id'] as String,
        url: json['url'] as String,
        storagePath: json['storage_path'] as String,
        esPrincipal: json['es_principal'] as bool? ?? false,
        orden: json['orden'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'entrada_id': entradaId,
        'url': url,
        'storage_path': storagePath,
        'es_principal': esPrincipal,
        'orden': orden,
      };

  FotoModel copyWith({bool? esPrincipal, int? orden}) => FotoModel(
        id: id,
        entradaId: entradaId,
        url: url,
        storagePath: storagePath,
        esPrincipal: esPrincipal ?? this.esPrincipal,
        orden: orden ?? this.orden,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FotoModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
