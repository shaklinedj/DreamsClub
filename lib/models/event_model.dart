class Event {
  final int id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;

  Event({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}
