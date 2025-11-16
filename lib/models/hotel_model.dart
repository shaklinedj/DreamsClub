class Hotel {
  final int id;
  final int casinoId;
  final String nombre;
  final String categoria;
  final String descripcion;
  final String imageUrl;
  final List<String> servicios;
  final List<Habitacion> habitaciones;


  Hotel({
    required this.id,
    required this.casinoId,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.imageUrl,
    required this.servicios,
    required this.habitaciones,
  });
}

class Habitacion {
  final String nombre;
  final String descripcion;

  Habitacion({
    required this.nombre,
    required this.descripcion,
  });
}
