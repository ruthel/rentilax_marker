enum UnitType {
  water('water', 'Eau', 'm³', 'Mètres cubes'),
  electricity('electricity', 'Électricité', 'kWh', 'Kilowattheures'),
  gas('gas', 'Gaz', 'm³', 'Mètres cubes');

  const UnitType(this.id, this.name, this.symbol, this.fullName);

  final String id;
  final String name;
  final String symbol;
  final String fullName;

  static UnitType fromId(String id) {
    return UnitType.values.firstWhere(
      (unit) => unit.id == id,
      orElse: () => UnitType.water,
    );
  }

  @override
  String toString() => name;
}

class ConsumptionUnit {
  final int? id;
  final String name;
  final String symbol;
  final String fullName;
  final UnitType type;
  final double conversionFactor; // Facteur de conversion vers l'unité de base
  final bool isDefault;
  final DateTime dateCreation;

  ConsumptionUnit({
    this.id,
    required this.name,
    required this.symbol,
    required this.fullName,
    required this.type,
    this.conversionFactor = 1.0,
    this.isDefault = false,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'full_name': fullName,
      'type': type.id,
      'conversion_factor': conversionFactor,
      'is_default': isDefault ? 1 : 0,
      'date_creation': dateCreation.millisecondsSinceEpoch,
    };
  }

  factory ConsumptionUnit.fromMap(Map<String, dynamic> map) {
    return ConsumptionUnit(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      fullName: map['full_name'] ?? '',
      type: UnitType.fromId(map['type'] ?? 'water'),
      conversionFactor: map['conversion_factor']?.toDouble() ?? 1.0,
      isDefault: (map['is_default'] ?? 0) == 1,
      dateCreation: DateTime.fromMillisecondsSinceEpoch(
        map['date_creation'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  ConsumptionUnit copyWith({
    int? id,
    String? name,
    String? symbol,
    String? fullName,
    UnitType? type,
    double? conversionFactor,
    bool? isDefault,
    DateTime? dateCreation,
  }) {
    return ConsumptionUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      fullName: fullName ?? this.fullName,
      type: type ?? this.type,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      isDefault: isDefault ?? this.isDefault,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() => '$name ($symbol)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsumptionUnit &&
        other.id == id &&
        other.name == name &&
        other.symbol == symbol &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ symbol.hashCode ^ type.hashCode;
  }

  // Unités prédéfinies
  static List<ConsumptionUnit> get defaultUnits => [
        // Unités d'eau
        ConsumptionUnit(
          name: 'Mètre cube',
          symbol: 'm³',
          fullName: 'Mètres cubes',
          type: UnitType.water,
          conversionFactor: 1.0,
          isDefault: true,
        ),
        ConsumptionUnit(
          name: 'Litre',
          symbol: 'L',
          fullName: 'Litres',
          type: UnitType.water,
          conversionFactor: 0.001, // 1L = 0.001 m³
        ),
        ConsumptionUnit(
          name: 'Hectolitre',
          symbol: 'hL',
          fullName: 'Hectolitres',
          type: UnitType.water,
          conversionFactor: 0.1, // 1hL = 0.1 m³
        ),

        // Unités d'électricité
        ConsumptionUnit(
          name: 'Kilowattheure',
          symbol: 'kWh',
          fullName: 'Kilowattheures',
          type: UnitType.electricity,
          conversionFactor: 1.0,
          isDefault: true,
        ),
        ConsumptionUnit(
          name: 'Wattheure',
          symbol: 'Wh',
          fullName: 'Wattheures',
          type: UnitType.electricity,
          conversionFactor: 0.001, // 1Wh = 0.001 kWh
        ),
        ConsumptionUnit(
          name: 'Mégawattheure',
          symbol: 'MWh',
          fullName: 'Mégawattheures',
          type: UnitType.electricity,
          conversionFactor: 1000.0, // 1MWh = 1000 kWh
        ),

        // Unités de gaz
        ConsumptionUnit(
          name: 'Mètre cube (gaz)',
          symbol: 'm³',
          fullName: 'Mètres cubes de gaz',
          type: UnitType.gas,
          conversionFactor: 1.0,
          isDefault: true,
        ),
        ConsumptionUnit(
          name: 'Thermie',
          symbol: 'th',
          fullName: 'Thermies',
          type: UnitType.gas,
          conversionFactor: 0.086, // Approximation : 1 th ≈ 0.086 m³
        ),
      ];
}
