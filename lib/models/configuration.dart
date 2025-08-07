import 'unit_type.dart';

class Configuration {
  final int? id;
  final double tarifBase;
  final String devise;
  final int? defaultUnitId;
  final UnitType defaultUnitType;
  final DateTime dateModification;

  Configuration({
    this.id,
    required this.tarifBase,
    this.devise = 'FCFA',
    this.defaultUnitId,
    this.defaultUnitType = UnitType.water,
    required this.dateModification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarifBase': tarifBase,
      'devise': devise,
      'default_unit_id': defaultUnitId,
      'default_unit_type': defaultUnitType.id,
      'dateModification': dateModification.toIso8601String(),
    };
  }

  factory Configuration.fromMap(Map<String, dynamic> map) {
    return Configuration(
      id: map['id'],
      tarifBase: map['tarifBase'].toDouble(),
      devise: map['devise'] ?? 'FCFA',
      defaultUnitId: map['default_unit_id'],
      defaultUnitType: UnitType.fromId(map['default_unit_type'] ?? 'water'),
      dateModification: DateTime.parse(map['dateModification']),
    );
  }

  Configuration copyWith({
    int? id,
    double? tarifBase,
    String? devise,
    int? defaultUnitId,
    UnitType? defaultUnitType,
    DateTime? dateModification,
  }) {
    return Configuration(
      id: id ?? this.id,
      tarifBase: tarifBase ?? this.tarifBase,
      devise: devise ?? this.devise,
      defaultUnitId: defaultUnitId ?? this.defaultUnitId,
      defaultUnitType: defaultUnitType ?? this.defaultUnitType,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
