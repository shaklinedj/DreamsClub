
import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/models/restaurante_model.dart';

class Casino {
  final int id;
  final String nombre;
  final String ciudad;
  final String direccion;
  final double latitud;
  final double longitud;
  final String imageUrl;
  final Hotel? hotel;
  final List<Restaurante>? restaurantes;
  final List<String> features;
  final String description;
  final double rating;

  Casino({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.imageUrl,
    this.hotel,
    this.restaurantes,
    this.features = const [],
    this.description = '',
    this.rating = 4.5,
  });

  factory Casino.fromJson(Map<String, dynamic> json) {
    return Casino(
      id: json['id'],
      nombre: json['nombre'],
      ciudad: json['ciudad'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      imageUrl: json['imageUrl'],
      hotel: json['hotel'] != null ? Hotel.fromJson(json['hotel']) : null,
      restaurantes: json['restaurantes'] != null
          ? (json['restaurantes'] as List)
              .map((i) => Restaurante.fromJson(i))
              .toList()
          : null,
      features: json['features'] != null ? List<String>.from(json['features']) : [],
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
    );
  }
}
