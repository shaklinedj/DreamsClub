
class Event {
  final int id;
  final int casinoId; 
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String imageUrl; 
  final String type;
  final String location;
  final String price;

  Event({
    required this.id,
    required this.casinoId, 
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.imageUrl, 
    this.type = 'Evento',
    this.location = 'Main Stage',
    this.price = 'Gratis',
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      casinoId: json['casinoId'], 
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      imageUrl: json['imageUrl'], 
      type: json['type'] ?? 'Evento',
      location: json['location'] ?? 'Main Stage',
      price: json['price'] ?? 'Gratis',
    );
  }
}
