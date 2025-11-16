class Restaurante {
  final String id;
  final String casinoId;
  final String nombre;
  final String imageUrl;

  Restaurante({
    required this.id,
    required this.casinoId,
    required this.nombre, 
    required this.imageUrl
    });

  factory Restaurante.fromJson(Map<String, dynamic> json) {
    return Restaurante(
      id: json['id'],
      casinoId: json['casinoId'],
      nombre: json['nombre'],
      imageUrl: json['imageUrl'],
    );
  }
}
