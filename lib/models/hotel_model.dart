
class Hotel {
  final int id;
  final int casinoId;
  final String nombre;
  final String imageUrl;

  Hotel({
    required this.id,
    required this.casinoId,
    required this.nombre,
    required this.imageUrl,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      casinoId: json['casinoId'],
      nombre: json['nombre'],
      imageUrl: json['imageUrl'],
    );
  }
}
