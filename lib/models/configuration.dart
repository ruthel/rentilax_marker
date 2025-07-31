class Configuration {
  final int? id;
  final double tarifBase;
  final String devise;
  final DateTime dateModification;

  Configuration({
    this.id,
    required this.tarifBase,
    this.devise = 'FCFA',
    required this.dateModification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarifBase': tarifBase,
      'devise': devise,
      'dateModification': dateModification.toIso8601String(),
    };
  }

  factory Configuration.fromMap(Map<String, dynamic> map) {
    return Configuration(
      id: map['id'],
      tarifBase: map['tarifBase'].toDouble(),
      devise: map['devise'] ?? 'FCFA',
      dateModification: DateTime.parse(map['dateModification']),
    );
  }
}