class PaymentHistory {
  final int? id;
  final int releveId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;

  PaymentHistory({
    this.id,
    required this.releveId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'releve_id': releveId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      id: map['id'],
      releveId: map['releve_id'],
      amount: map['amount'].toDouble(),
      paymentMethod: map['payment_method'],
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date']),
      notes: map['notes'],
    );
  }
}
