import 'package:fl_chart/fl_chart.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import 'database_service.dart';

class AnalyticsService {
  static final DatabaseService _databaseService = DatabaseService();

  /// Récupère les tendances de consommation pour un locataire
  static Future<ConsumptionTrends> getConsumptionTrends(int locataireId,
      {int months = 12}) async {
    final releves = await _databaseService.getRelevesByLocataire(locataireId,
        limit: months);

    final monthlyData = <String, double>{};
    final consumptionData = <FlSpot>[];

    for (int i = 0; i < releves.length; i++) {
      final releve = releves[i];
      final monthKey = '${releve.moisReleve.month}/${releve.moisReleve.year}';
      monthlyData[monthKey] = releve.consommation;
      consumptionData.add(FlSpot(i.toDouble(), releve.consommation));
    }

    final averageConsumption = releves.isNotEmpty
        ? releves.map((r) => r.consommation).reduce((a, b) => a + b) /
            releves.length
        : 0.0;

    final maxConsumption = releves.isNotEmpty
        ? releves.map((r) => r.consommation).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final minConsumption = releves.isNotEmpty
        ? releves.map((r) => r.consommation).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return ConsumptionTrends(
      monthlyData: monthlyData,
      chartData: consumptionData,
      averageConsumption: averageConsumption,
      maxConsumption: maxConsumption,
      minConsumption: minConsumption,
      trend: _calculateTrend(releves),
    );
  }

  /// Calcule les statistiques financières globales
  static Future<FinancialAnalytics> getFinancialAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final releves = await _databaseService.getRelevesInPeriod(start, end);

    double totalRevenue = 0;
    double collectedRevenue = 0;
    double pendingRevenue = 0;
    int totalReadings = releves.length;
    int paidReadings = 0;

    final monthlyRevenue = <String, double>{};
    final revenueChartData = <FlSpot>[];

    for (final releve in releves) {
      totalRevenue += releve.montant;
      collectedRevenue += releve.paidAmount;
      pendingRevenue += (releve.montant - releve.paidAmount);

      if (releve.isPaid) paidReadings++;

      final monthKey = '${releve.moisReleve.month}/${releve.moisReleve.year}';
      monthlyRevenue[monthKey] =
          (monthlyRevenue[monthKey] ?? 0) + releve.montant;
    }

    // Préparer les données pour le graphique
    int index = 0;
    monthlyRevenue.forEach((month, revenue) {
      revenueChartData.add(FlSpot(index.toDouble(), revenue.toDouble()));
      index++;
    });

    final collectionRate =
        totalRevenue > 0 ? (collectedRevenue / totalRevenue) * 100 : 0.0;

    return FinancialAnalytics(
      totalRevenue: totalRevenue,
      collectedRevenue: collectedRevenue,
      pendingRevenue: pendingRevenue,
      collectionRate: collectionRate,
      totalReadings: totalReadings,
      paidReadings: paidReadings,
      unpaidReadings: totalReadings - paidReadings,
      monthlyRevenue: monthlyRevenue,
      revenueChartData: revenueChartData,
    );
  }

  /// Détecte les anomalies de consommation
  static Future<List<ConsumptionAnomaly>> detectAnomalies() async {
    final anomalies = <ConsumptionAnomaly>[];
    final locataires = await _databaseService.getLocataires();

    for (final locataire in locataires) {
      final releves =
          await _databaseService.getRelevesByLocataire(locataire.id!, limit: 6);

      if (releves.length >= 3) {
        final averageConsumption =
            releves.map((r) => r.consommation).reduce((a, b) => a + b) /
                releves.length;

        final latestConsumption = releves.first.consommation;

        // Anomalie si la consommation actuelle dépasse 150% de la moyenne
        if (latestConsumption > averageConsumption * 1.5) {
          anomalies.add(ConsumptionAnomaly(
            locataire: locataire,
            releve: releves.first,
            averageConsumption: averageConsumption,
            currentConsumption: latestConsumption,
            anomalyType: AnomalyType.highConsumption,
            severity: _calculateSeverity(latestConsumption, averageConsumption),
          ));
        }

        // Anomalie si la consommation actuelle est inférieure à 50% de la moyenne
        if (latestConsumption < averageConsumption * 0.5 &&
            latestConsumption > 0) {
          anomalies.add(ConsumptionAnomaly(
            locataire: locataire,
            releve: releves.first,
            averageConsumption: averageConsumption,
            currentConsumption: latestConsumption,
            anomalyType: AnomalyType.lowConsumption,
            severity: _calculateSeverity(latestConsumption, averageConsumption),
          ));
        }
      }
    }

    return anomalies;
  }

  /// Génère des prévisions de revenus
  static Future<RevenueForecasting> generateRevenueForecasting(
      {int months = 6}) async {
    final historicalData = await _databaseService.getRelevesInPeriod(
      DateTime.now().subtract(Duration(days: 365)),
      DateTime.now(),
    );

    // Calcul de la moyenne mensuelle
    final monthlyAverages = <int, double>{};
    for (final releve in historicalData) {
      final month = releve.moisReleve.month;
      monthlyAverages[month] = (monthlyAverages[month] ?? 0) + releve.montant;
    }

    // Calcul des prévisions
    final forecasts = <DateTime, double>{};
    final currentDate = DateTime.now();

    for (int i = 1; i <= months; i++) {
      final forecastDate = DateTime(currentDate.year, currentDate.month + i, 1);
      final month = forecastDate.month;
      final averageForMonth = monthlyAverages[month] ?? 0;

      // Appliquer une croissance estimée de 2% par an
      final growthFactor = 1 + (0.02 * i / 12);
      forecasts[forecastDate] = averageForMonth * growthFactor;
    }

    return RevenueForecasting(
      forecasts: forecasts,
      confidence: 0.75, // 75% de confiance
      basedOnMonths: historicalData.length,
    );
  }

  static ConsumptionTrend _calculateTrend(List<Releve> releves) {
    if (releves.length < 2) return ConsumptionTrend.stable;

    final recent =
        releves.take(3).map((r) => r.consommation).reduce((a, b) => a + b) / 3;
    final older = releves
            .skip(3)
            .take(3)
            .map((r) => r.consommation)
            .reduce((a, b) => a + b) /
        3;

    if (recent > older * 1.1) return ConsumptionTrend.increasing;
    if (recent < older * 0.9) return ConsumptionTrend.decreasing;
    return ConsumptionTrend.stable;
  }

  static AnomalySeverity _calculateSeverity(double current, double average) {
    final ratio = current / average;
    if (ratio > 2.0 || ratio < 0.3) return AnomalySeverity.high;
    if (ratio > 1.5 || ratio < 0.5) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }
}

// Classes de données pour les analyses
class ConsumptionTrends {
  final Map<String, double> monthlyData;
  final List<FlSpot> chartData;
  final double averageConsumption;
  final double maxConsumption;
  final double minConsumption;
  final ConsumptionTrend trend;

  ConsumptionTrends({
    required this.monthlyData,
    required this.chartData,
    required this.averageConsumption,
    required this.maxConsumption,
    required this.minConsumption,
    required this.trend,
  });
}

class FinancialAnalytics {
  final double totalRevenue;
  final double collectedRevenue;
  final double pendingRevenue;
  final double collectionRate;
  final int totalReadings;
  final int paidReadings;
  final int unpaidReadings;
  final Map<String, double> monthlyRevenue;
  final List<FlSpot> revenueChartData;

  FinancialAnalytics({
    required this.totalRevenue,
    required this.collectedRevenue,
    required this.pendingRevenue,
    required this.collectionRate,
    required this.totalReadings,
    required this.paidReadings,
    required this.unpaidReadings,
    required this.monthlyRevenue,
    required this.revenueChartData,
  });
}

class ConsumptionAnomaly {
  final Locataire locataire;
  final Releve releve;
  final double averageConsumption;
  final double currentConsumption;
  final AnomalyType anomalyType;
  final AnomalySeverity severity;

  ConsumptionAnomaly({
    required this.locataire,
    required this.releve,
    required this.averageConsumption,
    required this.currentConsumption,
    required this.anomalyType,
    required this.severity,
  });
}

class RevenueForecasting {
  final Map<DateTime, double> forecasts;
  final double confidence;
  final int basedOnMonths;

  RevenueForecasting({
    required this.forecasts,
    required this.confidence,
    required this.basedOnMonths,
  });
}

enum ConsumptionTrend { increasing, decreasing, stable }

enum AnomalyType { highConsumption, lowConsumption }

enum AnomalySeverity { low, medium, high }
