class Casino {
  final String id;
  final String nombre;
  final String ciudad;
  final String direccion;
  final double latitud;
  final double longitud;
  final String imageUrl;
  final List<String> features;
  final String description;
  final double rating;
  final Map<String, String>? schedules; // e.g. {'Lunes': '09:00 - 02:00', 'Viernes': '24h'}
  final String? reservationUrl;
  final String? websiteUrl;

  const Casino({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.imageUrl,
    this.features = const [],
    this.description = '',
    this.rating = 4.5,
    this.schedules,
    this.reservationUrl,
    this.websiteUrl,
  });

  factory Casino.fromJson(Map<String, dynamic> json) {
    return Casino.fromMap(json, json['id']?.toString() ?? '');
  }

  factory Casino.fromMap(Map<String, dynamic> map, String id) {
    final nombre = map['nombre'] as String? ?? '';
    final ciudad = map['ciudad'] as String? ?? '';
    final direccion = map['direccion'] as String? ?? '';
    final latitud = (map['latitud'] as num?)?.toDouble() ?? 0.0;
    final longitud = (map['longitud'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = map['imageUrl'] as String? ?? '';

    final List<String> features = map['features'] != null
        ? List<String>.from(map['features'])
        : <String>[];
    final description = map['description'] as String? ?? '';
    final rating = (map['rating'] as num?)?.toDouble() ?? 4.5;
    final schedules = map['schedules'] != null
        ? Map<String, String>.from(map['schedules'])
        : null;
    final reservationUrl = map['reservationUrl'] as String?;
    final websiteUrl = map['websiteUrl'] as String?;

    return Casino(
      id: id,
      nombre: nombre,
      ciudad: ciudad,
      direccion: direccion,
      latitud: latitud,
      longitud: longitud,
      imageUrl: imageUrl,
      features: features,
      description: description,
      rating: rating,
      schedules: schedules,
      reservationUrl: reservationUrl,
      websiteUrl: websiteUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'ciudad': ciudad,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'imageUrl': imageUrl,
      'features': features,
      'description': description,
      'rating': rating,
      'schedules': schedules,
      'reservationUrl': reservationUrl,
      'websiteUrl': websiteUrl,
    };
  }
}

