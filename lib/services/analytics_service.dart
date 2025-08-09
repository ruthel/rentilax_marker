import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../models/consumption_anomaly.dart';
import 'database_service.dart';

class AnalyticsService {
  final DatabaseService _databaseService = DatabaseService();

  // Métriques de revenus
  Future<RevenueAnalytics> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final releves = await _databaseService.getReleves();
    final config = await _databaseService.getConfiguration();

    final filteredReleves = _filterRelevesByDate(releves, startDate, endDate);

    final totalRevenue = filteredReleves.fold(0.0, (sum, r) => sum + r.montant);
    final paidRevenue = filteredReleves
        .where((r) => r.isPaid)
        .fold(0.0, (sum, r) => sum + r.montant);
    final unpaidRevenue = totalRevenue - paidRevenue;

    final monthlyData = _getMonthlyRevenueData(filteredReleves);
    final paymentStatusData = _getPaymentStatusData(filteredReleves);

    return RevenueAnalytics(
      totalRevenue: totalRevenue,
      paidRevenue: paidRevenue,
      unpaidRevenue: unpaidRevenue,
      monthlyData: monthlyData,
      paymentStatusData: paymentStatusData,
      currency: config.devise,
    );
  }

  // Métriques de consommation
  Future<ConsumptionAnalytics> getConsumptionAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final releves = await _databaseService.getReleves();
    final locataires = await _databaseService.getLocataires();
    final cites = await _databaseService.getCites();

    final filteredReleves = _filterRelevesByDate(releves, startDate, endDate);

    final totalConsumption =
        filteredReleves.fold(0.0, (sum, r) => sum + r.consommation);
    final averageConsumption = filteredReleves.isEmpty
        ? 0.0
        : totalConsumption / filteredReleves.length;

    final monthlyConsumption = _getMonthlyConsumptionData(filteredReleves);
    final consumptionByCite =
        _getConsumptionByCite(filteredReleves, locataires, cites);
    final consumptionByType = _getConsumptionByType(filteredReleves);

    return ConsumptionAnalytics(
      totalConsumption: totalConsumption,
      averageConsumption: averageConsumption,
      monthlyData: monthlyConsumption,
      byCiteData: consumptionByCite,
      byTypeData: consumptionByType,
    );
  }

  // Métriques des locataires
  Future<TenantAnalytics> getTenantAnalytics() async {
    final locataires = await _databaseService.getLocataires();
    final releves = await _databaseService.getReleves();
    final cites = await _databaseService.getCites();

    final totalTenants = locataires.length;
    final activeTenants = _getActiveTenants(locataires, releves);
    final tenantsByCite = _getTenantsByCite(locataires, cites);
    final paymentReliability =
        _getPaymentReliabilityScores(locataires, releves);

    return TenantAnalytics(
      totalTenants: totalTenants,
      activeTenants: activeTenants,
      tenantsByCite: tenantsByCite,
      paymentReliability: paymentReliability,
    );
  }

  // Métriques des cités
  Future<CiteAnalytics> getCiteAnalytics() async {
    final cites = await _databaseService.getCites();
    final locataires = await _databaseService.getLocataires();
    final releves = await _databaseService.getReleves();

    final citePerformance = <CitePerformance>[];

    for (final cite in cites) {
      final citeLocataires =
          locataires.where((l) => l.citeId == cite.id).toList();
      final citeReleves = releves.where((r) {
        try {
          final locataire = locataires.firstWhere(
            (l) => l.id == r.locataireId,
          );
          return locataire.citeId == cite.id;
        } catch (e) {
          return false;
        }
      }).toList();

      final totalRevenue = citeReleves.fold(0.0, (sum, r) => sum + r.montant);
      final paidRevenue = citeReleves
          .where((r) => r.isPaid)
          .fold(0.0, (sum, r) => sum + r.montant);
      final totalConsumption =
          citeReleves.fold(0.0, (sum, r) => sum + r.consommation);

      citePerformance.add(CitePerformance(
        cite: cite,
        tenantCount: citeLocataires.length,
        totalRevenue: totalRevenue,
        paidRevenue: paidRevenue,
        totalConsumption: totalConsumption,
        averageConsumption: citeLocataires.isEmpty
            ? 0.0
            : totalConsumption / citeLocataires.length,
        paymentRate:
            totalRevenue == 0 ? 0.0 : (paidRevenue / totalRevenue) * 100,
      ));
    }

    return CiteAnalytics(
      totalCites: cites.length,
      citePerformance: citePerformance,
    );
  }

  // Prédictions et tendances
  Future<PredictionAnalytics> getPredictionAnalytics() async {
    final releves = await _databaseService.getReleves();

    final monthlyRevenue = _getMonthlyRevenueData(releves);
    final monthlyConsumption = _getMonthlyConsumptionData(releves);

    final revenueTrend =
        _calculateTrend(monthlyRevenue.map((d) => d.value).toList());
    final consumptionTrend =
        _calculateTrend(monthlyConsumption.map((d) => d.value).toList());

    final nextMonthRevenue =
        _predictNextValue(monthlyRevenue.map((d) => d.value).toList());
    final nextMonthConsumption =
        _predictNextValue(monthlyConsumption.map((d) => d.value).toList());

    return PredictionAnalytics(
      revenueTrend: revenueTrend,
      consumptionTrend: consumptionTrend,
      predictedRevenue: nextMonthRevenue,
      predictedConsumption: nextMonthConsumption,
    );
  }

  // Méthodes utilitaires privées
  List<Releve> _filterRelevesByDate(
      List<Releve> releves, DateTime? start, DateTime? end) {
    if (start == null && end == null) return releves;

    return releves.where((releve) {
      if (start != null && releve.dateReleve.isBefore(start)) return false;
      if (end != null && releve.dateReleve.isAfter(end)) return false;
      return true;
    }).toList();
  }

  List<ChartDataPoint> _getMonthlyRevenueData(List<Releve> releves) {
    final monthlyData = <String, double>{};

    for (final releve in releves) {
      final monthKey =
          '${releve.moisReleve.year}-${releve.moisReleve.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + releve.montant;
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    return sortedKeys
        .map((key) => ChartDataPoint(
              label: _formatMonthLabel(key),
              value: monthlyData[key]!,
              date: DateTime.parse('$key-01'),
            ))
        .toList();
  }

  List<ChartDataPoint> _getMonthlyConsumptionData(List<Releve> releves) {
    final monthlyData = <String, double>{};

    for (final releve in releves) {
      final monthKey =
          '${releve.moisReleve.year}-${releve.moisReleve.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] =
          (monthlyData[monthKey] ?? 0) + releve.consommation;
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    return sortedKeys
        .map((key) => ChartDataPoint(
              label: _formatMonthLabel(key),
              value: monthlyData[key]!,
              date: DateTime.parse('$key-01'),
            ))
        .toList();
  }

  List<ChartDataPoint> _getPaymentStatusData(List<Releve> releves) {
    final paid = releves.where((r) => r.isPaid).length.toDouble();
    final unpaid = releves.where((r) => !r.isPaid).length.toDouble();

    return [
      ChartDataPoint(label: 'Payé', value: paid),
      ChartDataPoint(label: 'Non payé', value: unpaid),
    ];
  }

  List<ChartDataPoint> _getConsumptionByCite(
      List<Releve> releves, List<Locataire> locataires, List<Cite> cites) {
    final citeConsumption = <int, double>{};

    for (final releve in releves) {
      try {
        final locataire = locataires.firstWhere(
          (l) => l.id == releve.locataireId,
        );
        citeConsumption[locataire.citeId] =
            (citeConsumption[locataire.citeId] ?? 0) + releve.consommation;
      } catch (e) {
        // Ignorer les relevés sans locataire correspondant
        continue;
      }
    }

    return citeConsumption.entries.map((entry) {
      final cite = cites.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
      );
      return ChartDataPoint(
        label: cite.nom,
        value: entry.value,
      );
    }).toList();
  }

  List<ChartDataPoint> _getConsumptionByType(List<Releve> releves) {
    final typeConsumption = <String, double>{};

    for (final releve in releves) {
      final typeName = releve.unitType.name;
      typeConsumption[typeName] =
          (typeConsumption[typeName] ?? 0) + releve.consommation;
    }

    return typeConsumption.entries
        .map((entry) => ChartDataPoint(
              label: entry.key,
              value: entry.value,
            ))
        .toList();
  }

  int _getActiveTenants(List<Locataire> locataires, List<Releve> releves) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    final activeIds = releves
        .where((r) => r.dateReleve.isAfter(threeMonthsAgo))
        .map((r) => r.locataireId)
        .toSet();

    return activeIds.length;
  }

  List<ChartDataPoint> _getTenantsByCite(
      List<Locataire> locataires, List<Cite> cites) {
    final citeCounts = <int, int>{};

    for (final locataire in locataires) {
      citeCounts[locataire.citeId] = (citeCounts[locataire.citeId] ?? 0) + 1;
    }

    return citeCounts.entries.map((entry) {
      final cite = cites.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
      );
      return ChartDataPoint(
        label: cite.nom,
        value: entry.value.toDouble(),
      );
    }).toList();
  }

  List<TenantReliability> _getPaymentReliabilityScores(
      List<Locataire> locataires, List<Releve> releves) {
    return locataires.map((locataire) {
      final locataireReleves =
          releves.where((r) => r.locataireId == locataire.id).toList();

      if (locataireReleves.isEmpty) {
        return TenantReliability(
          locataire: locataire,
          reliabilityScore: 0.0,
          totalReleves: 0,
          paidReleves: 0,
        );
      }

      final paidCount = locataireReleves.where((r) => r.isPaid).length;
      final score = (paidCount / locataireReleves.length) * 100;

      return TenantReliability(
        locataire: locataire,
        reliabilityScore: score,
        totalReleves: locataireReleves.length,
        paidReleves: paidCount,
      );
    }).toList();
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    // S'assurer qu'on a assez de données pour faire une comparaison
    if (values.length < 6) {
      // Pour les petites listes, comparer simplement la première et dernière valeur
      final first = values.first;
      final last = values.last;
      return first == 0 ? 0.0 : ((last - first) / first) * 100;
    }

    final recentCount = (values.length / 2).floor().clamp(1, 3);
    final recent = values.sublist(values.length - recentCount);
    final older = values.sublist(0, values.length - recentCount);

    if (older.isEmpty) return 0.0;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    return olderAvg == 0 ? 0.0 : ((recentAvg - olderAvg) / olderAvg) * 100;
  }

  double _predictNextValue(List<double> values) {
    if (values.length < 3) return values.isEmpty ? 0.0 : values.last;

    // Simple linear regression pour prédiction
    final recentCount = (values.length).clamp(1, 6);
    final startIndex = (values.length - recentCount).clamp(0, values.length);
    final recent = values.sublist(startIndex);

    if (recent.isEmpty) return values.last;

    final sum = recent.reduce((a, b) => a + b);
    final avg = sum / recent.length;

    final trend = _calculateTrend(values);
    return avg * (1 + (trend / 100));
  }

  String _formatMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);

    const months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];

    return '${months[month]} $year';
  }

  /// Détecte les anomalies de consommation pour un locataire donné
  Future<List<ConsumptionAnomaly>> detectConsumptionAnomalies({
    int? locataireId,
    int monthsToAnalyze = 6,
    double thresholdPercentage = 25.0,
  }) async {
    final releves = await _databaseService.getReleves();
    final locataires = await _databaseService.getLocataires();

    final anomalies = <ConsumptionAnomaly>[];
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - monthsToAnalyze, now.day);

    // Filtrer les relevés par locataire si spécifié
    final relevesToAnalyze = locataireId != null
        ? releves.where((r) => r.locataireId == locataireId).toList()
        : releves;

    // Grouper par locataire
    final relevesByLocataire = <int, List<Releve>>{};
    for (final releve in relevesToAnalyze) {
      if (releve.dateReleve.isAfter(cutoffDate)) {
        relevesByLocataire
            .putIfAbsent(releve.locataireId, () => [])
            .add(releve);
      }
    }

    // Analyser chaque locataire
    for (final entry in relevesByLocataire.entries) {
      final locataireReleves = entry.value;
      final locataireIndex = locataires.indexWhere((l) => l.id == entry.key);
      if (locataireIndex == -1) continue;

      final locataire = locataires[locataireIndex];

      if (locataireReleves.length < 3) continue; // Pas assez de données

      // Calculer la moyenne historique (exclure le dernier relevé)
      final endIndex =
          (locataireReleves.length - 1).clamp(0, locataireReleves.length);
      final historicalReleves = locataireReleves.sublist(0, endIndex);

      if (historicalReleves.isEmpty) continue;

      final averageConsumption =
          historicalReleves.fold(0.0, (sum, r) => sum + r.consommation) /
              historicalReleves.length;

      // Analyser le dernier relevé
      final latestReleve = locataireReleves.last;
      final currentConsumption = latestReleve.consommation;

      if (averageConsumption > 0) {
        final deviationPercentage =
            ((currentConsumption - averageConsumption) / averageConsumption) *
                100;

        if (deviationPercentage.abs() >= thresholdPercentage) {
          final anomaly = ConsumptionAnomaly.fromReleve(
            releve: latestReleve,
            locataire: locataire,
            averageConsumption: averageConsumption,
          );
          anomalies.add(anomaly);
        }
      }
    }

    // Trier par sévérité (les plus critiques en premier)
    anomalies.sort((a, b) {
      final severityOrder = {
        AnomalySeverity.high: 3,
        AnomalySeverity.medium: 2,
        AnomalySeverity.low: 1,
      };
      return severityOrder[b.severity]!.compareTo(severityOrder[a.severity]!);
    });

    return anomalies;
  }

  /// Obtient les anomalies récentes (derniers 30 jours)
  Future<List<ConsumptionAnomaly>> getRecentAnomalies() async {
    return detectConsumptionAnomalies(
      monthsToAnalyze: 1,
      thresholdPercentage: 20.0,
    );
  }
}

// Modèles de données pour les analytics
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;
  final String? color;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
    this.color,
  });
}

class RevenueAnalytics {
  final double totalRevenue;
  final double paidRevenue;
  final double unpaidRevenue;
  final List<ChartDataPoint> monthlyData;
  final List<ChartDataPoint> paymentStatusData;
  final String currency;

  RevenueAnalytics({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.unpaidRevenue,
    required this.monthlyData,
    required this.paymentStatusData,
    required this.currency,
  });
}

class ConsumptionAnalytics {
  final double totalConsumption;
  final double averageConsumption;
  final List<ChartDataPoint> monthlyData;
  final List<ChartDataPoint> byCiteData;
  final List<ChartDataPoint> byTypeData;

  ConsumptionAnalytics({
    required this.totalConsumption,
    required this.averageConsumption,
    required this.monthlyData,
    required this.byCiteData,
    required this.byTypeData,
  });
}

class TenantAnalytics {
  final int totalTenants;
  final int activeTenants;
  final List<ChartDataPoint> tenantsByCite;
  final List<TenantReliability> paymentReliability;

  TenantAnalytics({
    required this.totalTenants,
    required this.activeTenants,
    required this.tenantsByCite,
    required this.paymentReliability,
  });
}

class CiteAnalytics {
  final int totalCites;
  final List<CitePerformance> citePerformance;

  CiteAnalytics({
    required this.totalCites,
    required this.citePerformance,
  });
}

class CitePerformance {
  final Cite cite;
  final int tenantCount;
  final double totalRevenue;
  final double paidRevenue;
  final double totalConsumption;
  final double averageConsumption;
  final double paymentRate;

  CitePerformance({
    required this.cite,
    required this.tenantCount,
    required this.totalRevenue,
    required this.paidRevenue,
    required this.totalConsumption,
    required this.averageConsumption,
    required this.paymentRate,
  });
}

class TenantReliability {
  final Locataire locataire;
  final double reliabilityScore;
  final int totalReleves;
  final int paidReleves;

  TenantReliability({
    required this.locataire,
    required this.reliabilityScore,
    required this.totalReleves,
    required this.paidReleves,
  });
}

class PredictionAnalytics {
  final double revenueTrend;
  final double consumptionTrend;
  final double predictedRevenue;
  final double predictedConsumption;

  PredictionAnalytics({
    required this.revenueTrend,
    required this.consumptionTrend,
    required this.predictedRevenue,
    required this.predictedConsumption,
  });
}
