
class Restaurante {
  final int id;
  final int casinoId;
  final String nombre;
  final String imageUrl;
  final String type;
  final String description;
  final double rating;
  final String priceRange;

  Restaurante({
    required this.id,
    required this.casinoId,
    required this.nombre,
    required this.imageUrl,
    this.type = 'Restaurante',
    this.description = '',
    this.rating = 4.5,
    this.priceRange = '\$\$',
  });

  factory Restaurante.fromJson(Map<String, dynamic> json) {
    return Restaurante(
      id: json['id'],
      casinoId: json['casinoId'],
      nombre: json['nombre'],
      imageUrl: json['imageUrl'],
      type: json['type'] ?? 'Restaurante',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      priceRange: json['priceRange'] ?? '\$\$',
    );
  }
}
