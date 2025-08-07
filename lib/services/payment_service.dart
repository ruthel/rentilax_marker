import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/payment_history.dart';
import 'database_service.dart';
import 'notification_service.dart';

class PaymentService {
  static final DatabaseService _databaseService = DatabaseService();

  /// Effectue un paiement partiel
  static Future<bool> makePartialPayment({
    required int releveId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final releve = await _databaseService.getReleveById(releveId);
      if (releve == null) return false;

      final remainingAmount = releve.montant - releve.paidAmount;
      if (amount > remainingAmount) return false;

      // Enregistrer le paiement partiel
      final paymentHistory = PaymentHistory(
        releveId: releveId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: DateTime.now(),
        notes: notes,
      );

      await _databaseService.insertPaymentHistory(paymentHistory);

      // Mettre à jour le relevé
      final newPaidAmount = releve.paidAmount + amount;
      final isFullyPaid = newPaidAmount >= releve.montant;

      await _databaseService.updatePaymentAmount(
        releveId,
        newPaidAmount,
        isFullyPaid,
        isFullyPaid ? DateTime.now() : null,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'historique des paiements pour un relevé
  static Future<List<PaymentHistory>> getPaymentHistory(int releveId) async {
    return await _databaseService.getPaymentHistory(releveId);
  }

  /// Envoie des rappels de paiement automatiques
  static Future<void> sendPaymentReminders() async {
    final overdueReleves = await _databaseService.getOverdueReleves();

    for (final releve in overdueReleves) {
      final locataire =
          await _databaseService.getLocataireById(releve.locataireId);
      if (locataire != null) {
        await NotificationService.sendPaymentReminder(locataire, releve);
      }
    }
  }

  /// Génère un reçu de paiement
  static Future<String> generatePaymentReceipt({
    required Releve releve,
    required Locataire locataire,
    required PaymentHistory payment,
  }) async {
    // Logique de génération de reçu
    return 'Reçu généré pour ${locataire.nomComplet} - ${payment.amount} FCFA';
  }

  /// Calcule les statistiques de paiement
  static Future<PaymentStats> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final releves = await _databaseService.getRelevesInPeriod(
      startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      endDate ?? DateTime.now(),
    );

    double totalAmount = 0;
    double paidAmount = 0;
    int totalReleves = releves.length;
    int paidReleves = 0;

    for (final releve in releves) {
      totalAmount += releve.montant;
      paidAmount += releve.paidAmount;
      if (releve.isPaid) paidReleves++;
    }

    return PaymentStats(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      unpaidAmount: totalAmount - paidAmount,
      totalReleves: totalReleves,
      paidReleves: paidReleves,
      unpaidReleves: totalReleves - paidReleves,
      paymentRate: totalReleves > 0 ? (paidReleves / totalReleves) * 100 : 0,
    );
  }
}

class PaymentStats {
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;
  final int totalReleves;
  final int paidReleves;
  final int unpaidReleves;
  final double paymentRate;

  PaymentStats({
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.totalReleves,
    required this.paidReleves,
    required this.unpaidReleves,
    required this.paymentRate,
  });
}
