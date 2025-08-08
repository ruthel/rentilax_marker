import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/consumption_anomaly.dart';
import '../services/analytics_service.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() =>
      _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  RevenueAnalytics? _revenueAnalytics;
  ConsumptionAnalytics? _consumptionAnalytics;
  List<ConsumptionAnomaly> _anomalies = [];
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
      final analyticsService = AnalyticsService();
      final revenueAnalytics = await analyticsService.getRevenueAnalytics();
      final consumptionAnalytics =
          await analyticsService.getConsumptionAnalytics();
      final anomalies = await analyticsService.detectConsumptionAnomalies();

      setState(() {
        _revenueAnalytics = revenueAnalytics;
        _consumptionAnalytics = consumptionAnalytics;
        _anomalies = anomalies;
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
        title: const Text('Dashboard Avancé'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.attach_money), text: 'Revenus'),
            Tab(icon: Icon(Icons.water_drop), text: 'Consommation'),
            Tab(icon: Icon(Icons.warning), text: 'Anomalies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildConsumptionTab(),
                _buildAnomaliesTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildKPICards(),
          const SizedBox(height: 24),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Revenus Totaux',
            '${_revenueAnalytics?.totalRevenue.toStringAsFixed(0) ?? '0'} ${_revenueAnalytics?.currency ?? 'FCFA'}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Consommation',
            '${_consumptionAnalytics?.totalConsumption.toStringAsFixed(1) ?? '0'} unités',
            Icons.water_drop,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Payé',
                  '${_revenueAnalytics?.paidRevenue.toStringAsFixed(0) ?? '0'}',
                  Colors.green,
                ),
                _buildStatItem(
                  'En attente',
                  '${_revenueAnalytics?.unpaidRevenue.toStringAsFixed(0) ?? '0'}',
                  Colors.orange,
                ),
                _buildStatItem(
                  'Anomalies',
                  '${_anomalies.length}',
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse des Revenus',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_revenueAnalytics != null) ...[
            _buildRevenueChart(),
            const SizedBox(height: 24),
            _buildPaymentStatusChart(),
          ] else
            const Center(child: Text('Aucune donnée disponible')),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution des Revenus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      spots: _revenueAnalytics!.monthlyData
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.value,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
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

  Widget _buildPaymentStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statut des Paiements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _revenueAnalytics!.paymentStatusData
                      .map((data) => PieChartSectionData(
                            value: data.value,
                            title: '${data.value.toInt()}',
                            color: data.label == 'Payé'
                                ? Colors.green
                                : Colors.orange,
                            radius: 60,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse de Consommation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_consumptionAnalytics != null) ...[
            _buildConsumptionChart(),
            const SizedBox(height: 24),
            _buildConsumptionByCiteChart(),
          ] else
            const Center(child: Text('Aucune donnée disponible')),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution de la Consommation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: _consumptionAnalytics!.monthlyData
                      .asMap()
                      .entries
                      .map((entry) => BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionByCiteChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consommation par Cité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _consumptionAnalytics!.byCiteData
                      .map((data) => PieChartSectionData(
                            value: data.value,
                            title: data.label,
                            color: Colors.primaries[_consumptionAnalytics!
                                    .byCiteData
                                    .indexOf(data) %
                                Colors.primaries.length],
                            radius: 60,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anomalies de Consommation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_anomalies.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Aucune anomalie détectée',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._anomalies.map((anomaly) => Card(
                  child: ListTile(
                    leading: Icon(
                      anomaly.deviationPercentage > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _getAnomalySeverityColor(anomaly.severity),
                    ),
                    title: Text(anomaly.locataire.nomComplet),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(anomaly.description),
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
