
class Event {
  final int id;
  final int casinoId; 
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String imageUrl; 

  Event({
    required this.id,
    required this.casinoId, 
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.imageUrl, 
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      casinoId: json['casinoId'], 
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      imageUrl: json['imageUrl'], 
    );
  }
}
