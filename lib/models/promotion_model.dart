class Promotion {
  final int id;
  final String titulo;
  final String descripcion;

  Promotion({
    required this.id,
    required this.titulo,
    required this.descripcion,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
    );
  }
}
