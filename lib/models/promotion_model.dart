class Promotion {
  final int id;
  final int casinoId; // Añadido
  final String titulo;
  final String descripcion;
  final String imageUrl; // Añadido

  Promotion({
    required this.id,
    required this.casinoId, // Añadido
    required this.titulo,
    required this.descripcion,
    required this.imageUrl, // Añadido
  });

  // El método fromJson no es necesario para datos locales, pero lo mantenemos por si acaso
  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      casinoId: json['casinoId'], // Añadido
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imageUrl: json['imageUrl'], // Añadido
    );
  }
}
