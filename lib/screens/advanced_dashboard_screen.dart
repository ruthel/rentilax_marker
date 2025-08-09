import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/advanced_charts.dart';
import '../widgets/animated_list_item.dart';

class AdvancedDashboardScreen extends StatefulWidget {
  const AdvancedDashboardScreen({super.key});

  @override
  State<AdvancedDashboardScreen> createState() =>
      _AdvancedDashboardScreenState();
}

class _AdvancedDashboardScreenState extends State<AdvancedDashboardScreen>
    with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();

  // Data
  RevenueAnalytics? _revenueAnalytics;
  ConsumptionAnalytics? _consumptionAnalytics;
  TenantAnalytics? _tenantAnalytics;
  CiteAnalytics? _citeAnalytics;
  PredictionAnalytics? _predictionAnalytics;

  // State
  bool _isLoading = true;
  String _selectedPeriod = '6months';

  // Animation controllers
  late TabController _tabController;
  late AnimationController _kpiAnimationController;
  late Animation<double> _kpiAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAnalytics();
  }

  void _setupAnimations() {
    _tabController = TabController(length: 4, vsync: this);

    _kpiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _kpiAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _kpiAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kpiAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final dateRange = _getDateRange(_selectedPeriod);

      final results = await Future.wait([
        _analyticsService.getRevenueAnalytics(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        ),
        _analyticsService.getConsumptionAnalytics(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        ),
        _analyticsService.getTenantAnalytics(),
        _analyticsService.getCiteAnalytics(),
        _analyticsService.getPredictionAnalytics(),
      ]);

      setState(() {
        _revenueAnalytics = results[0] as RevenueAnalytics;
        _consumptionAnalytics = results[1] as ConsumptionAnalytics;
        _tenantAnalytics = results[2] as TenantAnalytics;
        _citeAnalytics = results[3] as CiteAnalytics;
        _predictionAnalytics = results[4] as PredictionAnalytics;
        _isLoading = false;
      });

      _kpiAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Map<String, DateTime?> _getDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case '1month':
        return {
          'start': DateTime(now.year, now.month - 1, now.day),
          'end': now,
        };
      case '3months':
        return {
          'start': DateTime(now.year, now.month - 3, now.day),
          'end': now,
        };
      case '6months':
        return {
          'start': DateTime(now.year, now.month - 6, now.day),
          'end': now,
        };
      case '1year':
        return {
          'start': DateTime(now.year - 1, now.month, now.day),
          'end': now,
        };
      case 'all':
      default:
        return {'start': null, 'end': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Vérification de sécurité pour éviter les erreurs null
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: ModernAppBar(
        title: 'Dashboard Analytics',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range_rounded),
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1month', child: Text('1 mois')),
              const PopupMenuItem(value: '3months', child: Text('3 mois')),
              const PopupMenuItem(value: '6months', child: Text('6 mois')),
              const PopupMenuItem(value: '1year', child: Text('1 an')),
              const PopupMenuItem(value: 'all', child: Text('Tout')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
                text: 'Vue d\'ensemble',
                icon: Icon(Icons.dashboard_rounded, size: 18)),
            Tab(
                text: 'Revenus',
                icon: Icon(Icons.attach_money_rounded, size: 18)),
            Tab(
                text: 'Consommation',
                icon: Icon(Icons.water_drop_rounded, size: 18)),
            Tab(
                text: 'Prédictions',
                icon: Icon(Icons.trending_up_rounded, size: 18)),
          ],
          labelStyle: theme.textTheme.labelMedium,
          unselectedLabelStyle: theme.textTheme.labelMedium,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
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
                _buildPredictionTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs principaux
            _buildMainKPIs(),

            const SizedBox(height: 24),

            // Graphiques de synthèse
            Row(
              spacing: 6,
              children: [
                Expanded(
                  child: AdvancedLineChart(
                    data: _revenueAnalytics?.monthlyData ?? [],
                    title: 'Évolution des revenus',
                    subtitle: 'Derniers mois',
                    unit: _revenueAnalytics?.currency ?? 'FCFA',
                    height: 250,
                  ),
                ),
                Expanded(
                  child: AdvancedBarChart(
                    data: _consumptionAnalytics?.byCiteData ?? [],
                    title: 'Consommation par cité',
                    subtitle: 'Répartition actuelle',
                    unit: 'm³',
                    height: 250,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Performance des cités
            if (_citeAnalytics != null) _buildCitePerformanceSection(),

            const SizedBox(height: 24),

            // Top locataires
            if (_tenantAnalytics != null) _buildTopTenantsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Métriques de revenus
            _buildRevenueKPIs(),

            const SizedBox(height: 24),

            // Graphique d'évolution
            AdvancedLineChart(
              data: _revenueAnalytics?.monthlyData ?? [],
              title: 'Évolution des revenus mensuels',
              subtitle: 'Tendance sur la période sélectionnée',
              unit: _revenueAnalytics?.currency ?? 'FCFA',
              height: 300,
            ),

            const SizedBox(height: 24),

            // Répartition des paiements
            AdvancedPieChart(
              data: _revenueAnalytics?.paymentStatusData ?? [],
              title: 'Répartition des paiements',
              subtitle: 'Statut actuel des relevés',
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Métriques de consommation
            _buildConsumptionKPIs(),

            const SizedBox(height: 24),

            // Évolution mensuelle
            AdvancedLineChart(
              data: _consumptionAnalytics?.monthlyData ?? [],
              title: 'Évolution de la consommation',
              subtitle: 'Tendance mensuelle',
              unit: 'm³',
              height: 300,
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                // Par cité
                Expanded(
                  child: AdvancedBarChart(
                    data: _consumptionAnalytics?.byCiteData ?? [],
                    title: 'Consommation par cité',
                    unit: 'm³',
                    height: 250,
                  ),
                ),
                const SizedBox(width: 16),
                // Par type
                Expanded(
                  child: AdvancedPieChart(
                    data: _consumptionAnalytics?.byTypeData ?? [],
                    title: 'Répartition par type',
                    height: 250,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Métriques de prédiction
            _buildPredictionKPIs(),

            const SizedBox(height: 24),

            // Graphiques de tendances
            Text(
              'Analyse des tendances et prédictions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: 16),

            Text(
              'Cette section affichera des prédictions basées sur l\'historique des données et des algorithmes d\'apprentissage automatique.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Placeholder pour futures fonctionnalités
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prédictions avancées',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fonctionnalité en cours de développement',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildMainKPIs() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _kpiAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 6,
            children: [
              SizedBox(
                width: 150,
                child: _buildKPICard(
                  'Revenus totaux',
                  '${(_revenueAnalytics?.totalRevenue ?? 0).toStringAsFixed(0)} ${_revenueAnalytics?.currency ?? 'FCFA'}',
                  Icons.attach_money_rounded,
                  colorScheme.primary,
                  _predictionAnalytics?.revenueTrend ?? 0,
                ),
              ),
              SizedBox(
                width: 150,
                child: _buildKPICard(
                  'Consommation',
                  '${(_consumptionAnalytics?.totalConsumption ?? 0).toStringAsFixed(1)} m³',
                  Icons.water_drop_rounded,
                  Colors.blue,
                  _predictionAnalytics?.consumptionTrend ?? 0,
                ),
              ),
              SizedBox(
                width: 150,
                child: _buildKPICard(
                  'Locataires',
                  '${_tenantAnalytics?.totalTenants ?? 0}',
                  Icons.people_rounded,
                  Colors.green,
                  null,
                ),
              ),
              SizedBox(
                width: 150,
                child: _buildKPICard(
                  'Cités',
                  '${_citeAnalytics?.totalCites ?? 0}',
                  Icons.location_city_rounded,
                  Colors.orange,
                  null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    double? trend,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Transform.scale(
      scale: _kpiAnimation.value > 1.0 ? 1.0 : _kpiAnimation.value,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (trend != null)
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: trend >= 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trend >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 12,
                                color: trend >= 0 ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${trend.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: trend >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueKPIs() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Revenus payés',
              '${(_revenueAnalytics?.paidRevenue ?? 0).toStringAsFixed(0)} ${_revenueAnalytics?.currency ?? 'FCFA'}',
              Icons.check_circle_rounded,
              Colors.green,
              null,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Revenus impayés',
              '${(_revenueAnalytics?.unpaidRevenue ?? 0).toStringAsFixed(0)} ${_revenueAnalytics?.currency ?? 'FCFA'}',
              Icons.pending_rounded,
              Colors.red,
              null,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Taux de paiement',
              '${_calculatePaymentRate()}%',
              Icons.percent_rounded,
              colorScheme.primary,
              null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionKPIs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Consommation totale',
              '${(_consumptionAnalytics?.totalConsumption ?? 0).toStringAsFixed(1)} m³',
              Icons.water_drop_rounded,
              Colors.blue,
              null,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Consommation moy.',
              '${(_consumptionAnalytics?.averageConsumption ?? 0).toStringAsFixed(1)} m³',
              Icons.analytics_rounded,
              Colors.teal,
              null,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Locataires actifs',
              '${_tenantAnalytics?.activeTenants ?? 0}',
              Icons.people_alt_rounded,
              Colors.green,
              null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionKPIs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Tendance revenus',
              '${(_predictionAnalytics?.revenueTrend ?? 0).toStringAsFixed(1)}%',
              Icons.trending_up_rounded,
              (_predictionAnalytics?.revenueTrend ?? 0) >= 0
                  ? Colors.green
                  : Colors.red,
              null,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Prédiction revenus',
              '${(_predictionAnalytics?.predictedRevenue ?? 0).toStringAsFixed(0)} ${_revenueAnalytics?.currency ?? 'FCFA'}',
              Icons.auto_graph_rounded,
              Colors.purple,
              null,
            ),
          ),
          SizedBox(
            width: 150,
            child: _buildKPICard(
              'Consommation',
              '${(_predictionAnalytics?.predictedConsumption ?? 0).toStringAsFixed(1)} m³',
              Icons.water_rounded,
              Colors.indigo,
              null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitePerformanceSection() {
    final theme = Theme.of(context);
    final citePerformance = _citeAnalytics?.citePerformance ?? [];

    if (citePerformance.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance des cités',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...citePerformance.asMap().entries.map((entry) {
          final index = entry.key;
          final performance = entry.value;

          return AnimatedListItem(
            index: index,
            child: _buildCitePerformanceCard(performance),
          );
        }),
      ],
    );
  }

  Widget _buildCitePerformanceCard(CitePerformance performance) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  performance.cite.nom,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentRateColor(performance.paymentRate)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${performance.paymentRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getPaymentRateColor(performance.paymentRate),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'Locataires',
                  '${performance.tenantCount}',
                  Icons.people_rounded,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  'Revenus',
                  '${performance.totalRevenue.toStringAsFixed(0)} FCFA',
                  Icons.attach_money_rounded,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  'Consommation',
                  '${performance.totalConsumption.toStringAsFixed(1)} m³',
                  Icons.water_drop_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTopTenantsSection() {
    final theme = Theme.of(context);
    final paymentReliability = _tenantAnalytics?.paymentReliability ?? [];

    if (paymentReliability.isEmpty) {
      return const SizedBox.shrink();
    }

    final topTenants = paymentReliability
        .where((t) => t.totalReleves > 0)
        .toList()
      ..sort((a, b) => b.reliabilityScore.compareTo(a.reliabilityScore));

    final displayTenants = topTenants.take(5).toList();

    if (displayTenants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top locataires (fiabilité de paiement)',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...displayTenants.asMap().entries.map((entry) {
          final index = entry.key;
          final tenant = entry.value;

          return AnimatedListItem(
            index: index,
            child: _buildTenantReliabilityCard(tenant, index + 1),
          );
        }),
      ],
    );
  }

  Widget _buildTenantReliabilityCard(TenantReliability tenant, int rank) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.locataire.nomComplet,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Logement ${tenant.locataire.numeroLogement}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tenant.reliabilityScore.toStringAsFixed(1)}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getReliabilityColor(tenant.reliabilityScore),
                ),
              ),
              Text(
                '${tenant.paidReleves}/${tenant.totalReleves}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPaymentRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Color _getReliabilityColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _calculatePaymentRate() {
    if (_revenueAnalytics == null || _revenueAnalytics!.totalRevenue == 0) {
      return '0.0';
    }
    final rate =
        (_revenueAnalytics!.paidRevenue / _revenueAnalytics!.totalRevenue) *
            100;
    return rate.toStringAsFixed(1);
  }
}
