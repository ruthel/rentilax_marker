class Releve {
  final int? id;
  final int locataireId;
  final double ancienIndex;
  final double nouvelIndex;
  final double consommation;
  final double tarif;
  final double montant;
  final DateTime dateReleve;
  final DateTime moisReleve;
  final String? commentaire;
  final bool isPaid;
  final DateTime? paymentDate;
  final double paidAmount;

  Releve({
    this.id,
    required this.locataireId,
    required this.ancienIndex,
    required this.nouvelIndex,
    required this.tarif,
    required this.dateReleve,
    DateTime? moisReleve,
    this.commentaire,
    this.isPaid = false,
    this.paymentDate,
    this.paidAmount = 0.0,
  })  : consommation = nouvelIndex - ancienIndex,
        montant = (nouvelIndex - ancienIndex) * tarif,
        moisReleve = moisReleve ?? dateReleve;

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
      'moisReleve': moisReleve.toIso8601String(),
      'commentaire': commentaire,
      'isPaid': isPaid ? 1 : 0,
      'paymentDate': paymentDate?.toIso8601String(),
      'paidAmount': paidAmount,
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
      moisReleve: map['moisReleve'] != null
          ? DateTime.parse(map['moisReleve'])
          : DateTime.parse(map['dateReleve']),
      commentaire: map['commentaire'],
      isPaid: map['isPaid'] == 1,
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : null,
      paidAmount: map['paidAmount']?.toDouble() ?? 0.0,
    );
  }

  // Méthodes utilitaires pour les paiements
  double get remainingAmount => montant - paidAmount;
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < montant;
  double get paymentProgress => montant > 0 ? (paidAmount / montant) * 100 : 0;
}
