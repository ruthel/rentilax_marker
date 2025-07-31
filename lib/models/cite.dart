class Cite {
  final int? id;
  final String nom;
  final String? adresse;
  final DateTime dateCreation;

  Cite({
    this.id,
    required this.nom,
    this.adresse,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Cite.fromMap(Map<String, dynamic> map) {
    return Cite(
      id: map['id'],
      nom: map['nom'],
      adresse: map['adresse'],
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }
}