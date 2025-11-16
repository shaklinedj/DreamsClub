import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/models/restaurante_model.dart';

class Casino {
  final int id;
  final String nombre;
  final String ciudad;
  final String direccion;
  final String imageUrl;
  final double latitud;
  final double longitud;
  final Hotel? hotel;
  final List<Restaurante>? restaurantes;

  Casino({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.direccion,
    required this.imageUrl,
    required this.latitud,
    required this.longitud,
    this.hotel,
    this.restaurantes,
  });

  factory Casino.fromJson(Map<String, dynamic> json) {
    return Casino(
      id: json['id'],
      nombre: json['nombre'],
      ciudad: json['ciudad'],
      direccion: json['direccion'],
      imageUrl: json['imageUrl'] ?? '',
      latitud: json['latitud'],
      longitud: json['longitud'],
      hotel: json['hotel'] != null ? Hotel.fromJson(json['hotel']) : null,
      restaurantes: json['restaurantes'] != null
          ? (json['restaurantes'] as List)
              .map((i) => Restaurante.fromJson(i))
              .toList()
          : null,
    );
  }
}
