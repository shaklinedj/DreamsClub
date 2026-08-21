enum PrizeType {
  hotel,
  drink,
  food,
  tickets,
  chips,
  points,
  promotionalCredits,
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
  final bool isActive;

  const Prize({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.icon,
    required this.probability,
    this.daysValid = 7,
    this.validCasinos = const [],
    this.isActive = true,
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
      (e) => e.name == typeStr || 'PrizeType.$typeStr' == e.toString(),
      orElse: () => PrizeType.drink,
    );
    final daysValid = (json['daysValid'] as int?) ??
        (json['daysValid'] as num?)?.toInt() ??
        7;
    final validCasinosRaw = json['validCasinos'] as List?;
    final validCasinos = validCasinosRaw != null
        ? validCasinosRaw.map((e) => int.tryParse(e.toString()) ?? 0).toList()
        : <int>[];
    final isActive = json['isActive'] as bool? ?? true;

    return Prize(
      id: id,
      name: name,
      description: description,
      icon: icon,
      probability: probability,
      type: type,
      daysValid: daysValid,
      validCasinos: validCasinos,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'icon': icon,
      'probability': probability,
      'daysValid': daysValid,
      'validCasinos': validCasinos,
      'isActive': isActive,
    };
  }
}

// Fallback Default Prizes Pool
final List<Prize> mockPrizes = [
  const Prize(
    id: 'trago_cortesia',
    name: '1 Trago de Cortesía',
    type: PrizeType.drink,
    description: '1 trago o cóctel a elección en la barra de Dreams',
    icon: '🍸',
    probability: 25,
    daysValid: 7,
  ),
  const Prize(
    id: 'promocionales_3000',
    name: '\$3.000 en Promocionales',
    type: PrizeType.promotionalCredits,
    description: 'Créditos promocionales de \$3.000 para jugar en máquinas de azar',
    icon: '🎰',
    probability: 25,
    daysValid: 7,
  ),
  const Prize(
    id: 'entrada_gratis',
    name: '1 Entrada al Casino',
    type: PrizeType.tickets,
    description: 'Acceso liberado para 1 persona al Casino Dreams',
    icon: '🎟️',
    probability: 20,
    daysValid: 14,
  ),
  const Prize(
    id: 'sandwich_gourmet',
    name: '1 Sandwich Gourmet',
    type: PrizeType.food,
    description: '1 sandwich o hamburguesa a elección en restaurantes del casino',
    icon: '🍔',
    probability: 15,
    daysValid: 7,
  ),
  const Prize(
    id: 'cerveza_artesanal',
    name: '1 Cerveza / Cocktail',
    type: PrizeType.drink,
    description: '1 shop artesanal o cóctel en Lucky 7 Bar',
    icon: '🍺',
    probability: 15,
    daysValid: 7,
  ),
];
