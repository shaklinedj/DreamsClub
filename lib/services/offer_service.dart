import 'package:casinoloyalty_flutter/models/offer_model.dart';
import 'package:flutter/material.dart';

class OfferService {
  final List<Offer> _mockOffers = [
    // Offers for Casino 1 (Iquique)
    Offer(
      id: 1,
      title: '30% Dcto. en Bar Lucky 7',
      type: 'Gastronomía',
      icon: Icons.coffee,
      validity: 'Vence en 3 días',
      pointsCost: 0,
      casinoId: 1,
    ),
    Offer(
      id: 2,
      title: 'Noche Gratis - Hotel Dreams',
      type: 'Hotel',
      icon: Icons.hotel,
      validity: 'Válido todo el año',
      pointsCost: 60000,
      casinoId: 1,
    ),
    
    // Offers for Casino 5 (Monticello)
    Offer(
      id: 3,
      title: '\$10.000 Créditos Promocionales',
      type: 'Juego',
      icon: Icons.videogame_asset,
      validity: 'Vence hoy',
      pointsCost: 5000,
      casinoId: 5,
    ),
    Offer(
      id: 4,
      title: '2x1 en Buffet Capataz',
      type: 'Gastronomía',
      icon: Icons.restaurant,
      validity: 'Vence el domingo',
      pointsCost: 2000,
      casinoId: 5,
    ),
    Offer(
      id: 5,
      title: 'Entrada VIP a Club Suka',
      type: 'Entretenimiento',
      icon: Icons.music_note,
      validity: 'Válido viernes y sábados',
      pointsCost: 15000,
      casinoId: 5,
    ),

    // Offers for Casino 2 (Temuco)
    Offer(
      id: 6,
      title: 'Masaje de Relajación 30min',
      type: 'Spa',
      icon: Icons.spa,
      validity: 'Vence en 1 mes',
      pointsCost: 10000,
      casinoId: 2,
    ),
  ];

  Future<List<Offer>> getOffersByCasinoId(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockOffers.where((offer) => offer.casinoId == casinoId).toList();
  }
}
