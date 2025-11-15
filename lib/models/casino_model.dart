class Casino {
  final int id;
  final String nombre;
  final String ciudad;
  final String direccion;
  final double latitud;
  final double longitud;

  Casino({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });

  factory Casino.fromJson(Map<String, dynamic> json) {
    return Casino(
      id: json['id'],
      nombre: json['nombre'],
      ciudad: json['ciudad'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
    );
  }
}
