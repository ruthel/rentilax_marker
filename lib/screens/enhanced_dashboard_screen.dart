import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() =>
      _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  FinancialAnalytics? _financialAnalytics;
  List<ConsumptionAnomaly> _anomalies = [];
  PaymentStats? _paymentStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await AnalyticsService.getFinancialAnalytics();
      final anomalies = await AnalyticsService.detectAnomalies();
      final paymentStats = await PaymentService.getPaymentStats();

      setState(() {
        _financialAnalytics = analytics;
        _anomalies = anomalies;
        _paymentStats = paymentStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Avancé'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.trending_up), text: 'Revenus'),
            Tab(icon: Icon(Icons.warning), text: 'Alertes'),
            Tab(icon: Icon(Icons.payment), text: 'Paiements'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildAlertsTab(),
                _buildPaymentsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_financialAnalytics == null || _paymentStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Métriques principales
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Revenus Totaux',
                    '${_financialAnalytics!.totalRevenue.toStringAsFixed(0)} FCFA',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Taux de Recouvrement',
                    '${_financialAnalytics!.collectionRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    _financialAnalytics!.collectionRate > 80
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Relevés Payés',
                    '${_paymentStats!.paidReleves}/${_paymentStats!.totalReleves}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Alertes Actives',
                    '${_anomalies.length}',
                    Icons.warning,
                    _anomalies.isEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Graphique des revenus mensuels
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Évolution des Revenus',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: const FlTitlesData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _financialAnalytics!.revenueChartData,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab() {
    if (_financialAnalytics == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphique en secteurs des revenus
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Répartition des Revenus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: _financialAnalytics!.collectedRevenue,
                            title:
                                'Encaissé\n${_financialAnalytics!.collectedRevenue.toStringAsFixed(0)}',
                            color: Colors.green,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: _financialAnalytics!.pendingRevenue,
                            title:
                                'En attente\n${_financialAnalytics!.pendingRevenue.toStringAsFixed(0)}',
                            color: Colors.orange,
                            radius: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Détails mensuels
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenus par Mois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._financialAnalytics!.monthlyRevenue.entries.map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alertes de Consommation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.scheduleAutomaticReminders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rappels envoyés')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Envoyer Rappels'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_anomalies.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 16),
                    Text(
                      'Aucune anomalie détectée',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._anomalies.map((anomaly) => Card(
                  child: ListTile(
                    leading: Icon(
                      anomaly.anomalyType == AnomalyType.highConsumption
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _getAnomalySeverityColor(anomaly.severity),
                    ),
                    title: Text(anomaly.locataire.nomComplet),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anomaly.anomalyType == AnomalyType.highConsumption
                              ? 'Consommation élevée détectée'
                              : 'Consommation faible détectée',
                        ),
                        Text(
                          'Actuelle: ${anomaly.currentConsumption.toStringAsFixed(2)} | '
                          'Moyenne: ${anomaly.averageConsumption.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(_getAnomalySeverityText(anomaly.severity)),
                      backgroundColor:
                          _getAnomalySeverityColor(anomaly.severity)
                              .withValues(alpha: 0.2),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_paymentStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques de Paiement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Graphique en barres des paiements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'État des Paiements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: _paymentStats!.paidReleves.toDouble(),
                                color: Colors.green,
                                width: 40,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: _paymentStats!.unpaidReleves.toDouble(),
                                color: Colors.red,
                                width: 40,
                              ),
                            ],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Payés');
                                  case 1:
                                    return const Text('Impayés');
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Détails des paiements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPaymentDetailRow(
                    'Montant Total',
                    '${_paymentStats!.totalAmount.toStringAsFixed(0)} FCFA',
                    Icons.account_balance_wallet,
                  ),
                  _buildPaymentDetailRow(
                    'Montant Encaissé',
                    '${_paymentStats!.paidAmount.toStringAsFixed(0)} FCFA',
                    Icons.check_circle,
                  ),
                  _buildPaymentDetailRow(
                    'Montant en Attente',
                    '${_paymentStats!.unpaidAmount.toStringAsFixed(0)} FCFA',
                    Icons.pending,
                  ),
                  _buildPaymentDetailRow(
                    'Taux de Recouvrement',
                    '${_paymentStats!.paymentRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getAnomalySeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high:
        return Colors.red;
      case AnomalySeverity.medium:
        return Colors.orange;
      case AnomalySeverity.low:
        return Colors.yellow;
    }
  }

  String _getAnomalySeverityText(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high:
        return 'Élevée';
      case AnomalySeverity.medium:
        return 'Moyenne';
      case AnomalySeverity.low:
        return 'Faible';
    }
  }
}
