import 'package:casinoloyalty_flutter/models/hotel_model.dart';

class HotelService {
  final List<Hotel> _mockHotels = [
    Hotel(
        id: 1,
        casinoId: 5, // Monticello
        nombre: 'Hotel Monticello',
        categoria: '5 estrellas',
        descripcion:
            'Excelencia de servicio y calidad es el sello indiscutible del Hotel Monticello. Con sus 155 habitaciones, piscinas, bares y Spa, es el lugar ideal para la desconexión total.',
        imageUrl: 'https://dreams.cl/content/uploads/sites/2/2021/09/hotel-1.jpg',
        servicios: [
          'Piscina',
          'Spa',
          'Gimnasio',
          'Wifi Gratis'
        ],
        habitaciones: [
          Habitacion(
              nombre: 'DELUXE SUITE',
              descripcion: 'Amplia y lujosa suite con todas las comodidades.'),
          Habitacion(
              nombre: 'KING STANDARD EXECUTIVE',
              descripcion:
                  'Habitación ejecutiva con cama King y vista a la ciudad.'),
          Habitacion(
              nombre: 'PRESIDENCIAL DELUXE',
              descripcion: 'La suite más exclusiva con servicio de mayordomo.'),
          Habitacion(
              nombre: 'SUPERIOR EXECUTIVE',
              descripcion:
                  'Habitación superior con todas las comodidades para un viaje de negocios o placer.'),
        ]),
    Hotel(
        id: 2,
        casinoId: 1, // Iquique
        nombre: 'Hotel Dreams Iquique',
        categoria: '5 estrellas',
        descripcion:
            'Dreams Iquique es el único hotel 5 estrellas de la ciudad, te invita a vivir una experiencia inolvidable con una vista privilegiada frente al mar.',
        imageUrl: 'https://dreams.cl/content/uploads/sites/3/2021/09/hotel-1.jpg',
        servicios: [
          'Piscina al aire libre',
          'Gimnasio',
          'Spa'
        ],
        habitaciones: [
          Habitacion(
              nombre: 'ESTÁNDAR KING',
              descripcion: 'Habitación con cama King y vista al mar.'),
          Habitacion(
              nombre: 'ESTÁNDAR DOBLE',
              descripcion: 'Habitación con dos camas y vista a la ciudad.'),
          Habitacion(
              nombre: 'SUITE PRESIDENCIAL',
              descripcion: 'Lujo y exclusividad en la mejor suite del hotel.'),
        ]),
    Hotel(
        id: 3,
        casinoId: 2, // Temuco
        nombre: 'Hotel Dreams Temuco',
        categoria: '5 estrellas',
        descripcion:
            'Hotel de La Frontera es el único 5 estrellas de la IX Región. Con un servicio de excelencia, spa, gimnasio y la mejor gastronomía.',
        imageUrl: 'https://dreams.cl/content/uploads/sites/5/2021/09/hotel-1.jpg',
        servicios: [
          'Piscina temperada',
          'Gimnasio',
          'Spa'
        ],
        habitaciones: [
          Habitacion(
              nombre: 'ESTÁNDAR KING',
              descripcion: 'Comodidad y elegancia con vista a la ciudad.'),
          Habitacion(
              nombre: 'ESTÁNDAR DOBLE',
              descripcion: 'Amplitud y confort para toda la familia.'),
          Habitacion(
              nombre: 'SUITE DE LUJO',
              descripcion: 'Una experiencia de lujo inolvidable.'),
        ]),
    Hotel(
        id: 4,
        casinoId: 3, // Valdivia
        nombre: 'Hotel Dreams Valdivia',
        categoria: '4 estrellas',
        descripcion:
            'Emplazado a orillas del río Calle-Calle, nuestro hotel te invita a una estadía única en la hermosa ciudad de Valdivia. Conecta con la naturaleza y disfruta de un servicio de primer nivel.',
        imageUrl: 'https://dreams.cl/content/uploads/sites/4/2021/09/hotel-1.jpg',
        servicios: [
          'Piscina',
          'Gimnasio',
          'Spa'
        ],
        habitaciones: [
          Habitacion(
              nombre: 'HABITACIÓN DE LUJO',
              descripcion: 'Confort y estilo con vista al río.'),
          Habitacion(
              nombre: 'SUITE JUNIOR',
              descripcion: 'Amplitud y comodidad para una estadía perfecta.'),
          Habitacion(
              nombre: 'SUITE PRESIDENCIAL',
              descripcion: 'La máxima expresión de lujo y exclusividad.'),
        ]),
    Hotel(
        id: 5,
        casinoId: 4, // Punta Arenas
        nombre: 'Hotel Dreams del Estrecho',
        categoria: '5 estrellas',
        descripcion:
            'Con una vista inigualable al Estrecho de Magallanes, nuestro hotel te espera para brindarte una experiencia única en la Patagonia. Disfruta de la comodidad de nuestras instalaciones y de un servicio de excelencia.',
        imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg',
        servicios: [
          'Piscina',
          'Gimnasio',
          'Spa'
        ],
        habitaciones: [
          Habitacion(
              nombre: 'ESTÁNDAR KING',
              descripcion: 'Elegancia y confort con vista al Estrecho.'),
          Habitacion(
              nombre: 'ESTÁNDAR DOBLE',
              descripcion: 'Perfecta para familias o amigos.'),
          Habitacion(
              nombre: 'SUITE',
              descripcion: 'Disfruta de un espacio más amplio y exclusivo.'),
        ]),
  ];

  Future<List<Hotel>> getHotelsForCasino(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return _mockHotels.where((hotel) => hotel.casinoId == casinoId).toList();
  }
}
