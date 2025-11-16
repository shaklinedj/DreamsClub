
class Event {
  final int id;
  final int casinoId; // Añadido
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String imageUrl; // Añadido

  Event({
    required this.id,
    required this.casinoId, // Añadido
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.imageUrl, // Añadido
  });

  // El método fromJson no es necesario para datos locales, pero lo mantenemos por si acaso
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      casinoId: json['casinoId'], // Añadido
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      imageUrl: json['imageUrl'], // Añadido
    );
  }
}
