class Locataire {
  final int? id;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final int citeId;
  final String numeroLogement;
  final double? tarifPersonnalise;
  final DateTime dateEntree;

  Locataire({
    this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.email,
    required this.citeId,
    required this.numeroLogement,
    this.tarifPersonnalise,
    required this.dateEntree,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'citeId': citeId,
      'numeroLogement': numeroLogement,
      'tarifPersonnalise': tarifPersonnalise,
      'dateEntree': dateEntree.toIso8601String(),
    };
  }

  factory Locataire.fromMap(Map<String, dynamic> map) {
    return Locataire(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      telephone: map['telephone'],
      email: map['email'],
      citeId: map['citeId'],
      numeroLogement: map['numeroLogement'],
      tarifPersonnalise: map['tarifPersonnalise']?.toDouble(),
      dateEntree: DateTime.parse(map['dateEntree']),
    );
  }

  String get nomComplet => '$prenom $nom';
}