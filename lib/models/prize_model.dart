enum PrizeType {
  hotel,
  drink,
  food,
  tickets,
  chips,
  points,
}

class Prize {
  final String id;
  final String name;
  final PrizeType type;
  final String description;
  final String icon;
  final int probability; // 1-100
  final int daysValid;
  final List<int> validCasinos; // Empty = all casinos

  const Prize({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.icon,
    required this.probability,
    this.daysValid = 7,
    this.validCasinos = const [],
  });

  factory Prize.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final icon = json['icon'] as String? ?? '';
    final probability = (json['probability'] as int?) ??
        (json['probability'] as num?)?.toInt() ??
        0;
    final typeStr = json['type']?.toString();
    final type = PrizeType.values.firstWhere(
      (e) => 'PrizeType.$typeStr' == e.toString(),
      orElse: () => PrizeType.points,
    );
    final daysValid = (json['daysValid'] as int?) ??
        (json['daysValid'] as num?)?.toInt() ??
        7;
    final validCasinosRaw = json['validCasinos'] as List?;
    final validCasinos = validCasinosRaw != null
        ? validCasinosRaw.map((e) => int.tryParse(e.toString()) ?? 0).toList()
        : <int>[];

    return Prize(
      id: id,
      name: name,
      description: description,
      icon: icon,
      probability: probability,
      type: type,
      daysValid: daysValid,
      validCasinos: validCasinos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'description': description,
      'icon': icon,
      'probability': probability,
      'daysValid': daysValid,
      'validCasinos': validCasinos,
    };
  }
}

// Mock Prizes Data
final List<Prize> mockPrizes = [
  // Común (60% total)
  const Prize(
    id: 'coffee',
    name: 'Café Gratis',
    type: PrizeType.drink,
    description: 'Un café o té gratis en cualquier casino Dreams',
    icon: '☕',
    probability: 30,
    daysValid: 3,
  ),
  const Prize(
    id: 'points_500',
    name: '+500 Puntos Dreams',
    type: PrizeType.points,
    description: '500 puntos Dreams agregados a tu cuenta',
    icon: '💎',
    probability: 30,
    daysValid: 1, // Instant
  ),

  // Medio (30% total)
  const Prize(
    id: 'mojito_2x1',
    name: '2x1 en Mojitos',
    type: PrizeType.drink,
    description: 'Dos mojitos por el precio de uno en Bar Lucky 7',
    icon: '🍹',
    probability: 15,
    daysValid: 7,
  ),
  const Prize(
    id: 'discount_20',
    name: '20% Descuento Comida',
    type: PrizeType.food,
    description: '20% de descuento en cualquier restaurante Dreams',
    icon: '🍔',
    probability: 15,
    daysValid: 7,
  ),

  // Raro (10% total)
  const Prize(
    id: 'dinner_2',
    name: 'Cena para 2',
    type: PrizeType.food,
    description: 'Cena completa para dos personas en Doña Inés',
    icon: '🍽️',
    probability: 7,
    daysValid: 14,
  ),
  const Prize(
    id: 'hotel_night',
    name: '1 Noche en Hotel Dreams',
    type: PrizeType.hotel,
    description: 'Una noche gratis en habitación estándar',
    icon: '🏨',
    probability: 3,
    daysValid: 30,
  ),
];
