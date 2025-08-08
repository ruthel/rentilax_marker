import 'locataire.dart';
import 'releve.dart';

enum AnomalySeverity {
  low,
  medium,
  high,
}

class ConsumptionAnomaly {
  final Releve releve;
  final Locataire locataire;
  final double currentConsumption;
  final double averageConsumption;
  final double deviationPercentage;
  final AnomalySeverity severity;
  final DateTime detectedAt;

  ConsumptionAnomaly({
    required this.releve,
    required this.locataire,
    required this.currentConsumption,
    required this.averageConsumption,
    required this.deviationPercentage,
    required this.severity,
    required this.detectedAt,
  });

  /// Calcule la sévérité de l'anomalie basée sur le pourcentage de déviation
  static AnomalySeverity calculateSeverity(double deviationPercentage) {
    final absDeviation = deviationPercentage.abs();

    if (absDeviation >= 50) {
      return AnomalySeverity.high;
    } else if (absDeviation >= 25) {
      return AnomalySeverity.medium;
    } else {
      return AnomalySeverity.low;
    }
  }

  /// Crée une anomalie à partir d'un relevé et de ses données historiques
  static ConsumptionAnomaly fromReleve({
    required Releve releve,
    required Locataire locataire,
    required double averageConsumption,
  }) {
    final currentConsumption = releve.consommation;
    final deviationPercentage =
        ((currentConsumption - averageConsumption) / averageConsumption) * 100;

    return ConsumptionAnomaly(
      releve: releve,
      locataire: locataire,
      currentConsumption: currentConsumption,
      averageConsumption: averageConsumption,
      deviationPercentage: deviationPercentage,
      severity: calculateSeverity(deviationPercentage),
      detectedAt: DateTime.now(),
    );
  }

  /// Retourne une description textuelle de l'anomalie
  String get description {
    final isIncrease = deviationPercentage > 0;
    final changeType = isIncrease ? 'augmentation' : 'diminution';
    final emoji = isIncrease ? '📈' : '📉';

    return '$emoji ${changeType.toUpperCase()} de ${deviationPercentage.abs().toStringAsFixed(1)}% '
        'par rapport à la moyenne (${averageConsumption.toStringAsFixed(1)} unités)';
  }

  /// Retourne des recommandations basées sur l'anomalie
  List<String> get recommendations {
    final recommendations = <String>[];

    if (deviationPercentage > 0) {
      // Consommation élevée
      recommendations.addAll([
        'Vérifier les fuites potentielles',
        'Contrôler le compteur',
        'Sensibiliser le locataire à l\'économie',
      ]);

      if (severity == AnomalySeverity.high) {
        recommendations.add('Inspection urgente recommandée');
      }
    } else {
      // Consommation faible
      recommendations.addAll([
        'Vérifier le fonctionnement du compteur',
        'Confirmer la présence du locataire',
        'Contrôler les branchements',
      ]);
    }

    return recommendations;
  }

  @override
  String toString() {
    return 'ConsumptionAnomaly(locataire: ${locataire.nomComplet}, '
        'current: $currentConsumption, average: $averageConsumption, '
        'deviation: ${deviationPercentage.toStringAsFixed(1)}%, '
        'severity: $severity)';
  }
}
