class UnitTarif {
  final int? id;
  final int unitId;
  final double tarif;
  final String devise;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool isActive;

  UnitTarif({
    this.id,
    required this.unitId,
    required this.tarif,
    this.devise = 'FCFA',
    DateTime? dateCreation,
    this.dateModification,
    this.isActive = true,
  }) : dateCreation = dateCreation ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_id': unitId,
      'tarif': tarif,
      'devise': devise,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory UnitTarif.fromMap(Map<String, dynamic> map) {
    return UnitTarif(
      id: map['id'],
      unitId: map['unit_id'],
      tarif: map['tarif'].toDouble(),
      devise: map['devise'] ?? 'FCFA',
      dateCreation: map['date_creation'] is String
          ? DateTime.parse(map['date_creation'])
          : DateTime.fromMillisecondsSinceEpoch(map['date_creation']),
      dateModification: map['date_modification'] != null
          ? (map['date_modification'] is String
              ? DateTime.parse(map['date_modification'])
              : DateTime.fromMillisecondsSinceEpoch(map['date_modification']))
          : null,
      isActive: map['is_active'] == 1,
    );
  }

  UnitTarif copyWith({
    int? id,
    int? unitId,
    double? tarif,
    String? devise,
    DateTime? dateCreation,
    DateTime? dateModification,
    bool? isActive,
  }) {
    return UnitTarif(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      tarif: tarif ?? this.tarif,
      devise: devise ?? this.devise,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UnitTarif(id: $id, unitId: $unitId, tarif: $tarif, devise: $devise)';
  }
}
