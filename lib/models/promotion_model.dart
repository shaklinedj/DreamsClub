
class Promotion {
  final int id;
  final int casinoId;
  final String titulo;
  final String descripcion;
  final String imageUrl;

  Promotion({
    required this.id,
    required this.casinoId,
    required this.titulo,
    required this.descripcion,
    required this.imageUrl,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      casinoId: json['casinoId'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imageUrl: json['imageUrl'],
    );
  }
}
