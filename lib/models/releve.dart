class Releve {
  final int? id;
  final int locataireId;
  final double ancienIndex;
  final double nouvelIndex;
  final double consommation;
  final double tarif;
  final double montant;
  final DateTime dateReleve;
  final String? commentaire;

  Releve({
    this.id,
    required this.locataireId,
    required this.ancienIndex,
    required this.nouvelIndex,
    required this.tarif,
    required this.dateReleve,
    this.commentaire,
  }) : consommation = nouvelIndex - ancienIndex,
       montant = (nouvelIndex - ancienIndex) * tarif;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'locataireId': locataireId,
      'ancienIndex': ancienIndex,
      'nouvelIndex': nouvelIndex,
      'consommation': consommation,
      'tarif': tarif,
      'montant': montant,
      'dateReleve': dateReleve.toIso8601String(),
      'commentaire': commentaire,
    };
  }

  factory Releve.fromMap(Map<String, dynamic> map) {
    return Releve(
      id: map['id'],
      locataireId: map['locataireId'],
      ancienIndex: map['ancienIndex'].toDouble(),
      nouvelIndex: map['nouvelIndex'].toDouble(),
      tarif: map['tarif'].toDouble(),
      dateReleve: DateTime.parse(map['dateReleve']),
      commentaire: map['commentaire'],
    );
  }
}