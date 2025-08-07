import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import 'global_search_screen.dart';
import 'cites_screen.dart';
import 'locataires_screen.dart';
import 'releves_screen.dart';
import 'configuration_screen.dart';
import 'enhanced_dashboard_screen.dart';
import '../models/releve.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_stats_card.dart';
import '../widgets/modern_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  List<Releve> _monthlyReleves = [];
  List<Locataire> _allLocataires = [];
  List<Cite> _allCites = [];
  Configuration? _configuration;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMonthlyStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Rafraîchir les données quand l'app revient au premier plan
      _loadMonthlyStats();
    }
  }

  Future<void> _loadMonthlyStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final now = DateTime.now();
      final releves =
          await _databaseService.getRelevesForMonth(now.month, now.year);
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      final config = await _databaseService.getConfiguration();
      setState(() {
        _monthlyReleves = releves;
        _allLocataires = locataires;
        _allCites = cites;
        _configuration = config;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorLoadingStats)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    double totalConsommation =
        _monthlyReleves.fold(0.0, (sum, item) => sum + item.consommation);
    double totalMontant =
        _monthlyReleves.fold(0.0, (sum, item) => sum + item.montant);
    double totalPaidAmount = _monthlyReleves
        .where((releve) => releve.isPaid)
        .fold(0.0, (sum, item) => sum + item.montant);
    double totalUnpaidAmount = _monthlyReleves
        .where((releve) => !releve.isPaid)
        .fold(0.0, (sum, item) => sum + item.montant);

    return Scaffold(
      appBar: ModernAppBar(
        title: localizations.appTitle,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchScreen(),
                ),
              );
            },
            tooltip: 'Recherche globale',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMonthlyStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec le mois actuel
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.readingMonth,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                DateFormat.MMMM('fr_FR').format(DateTime.now()),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ModernButton(
                      text: localizations.printMonthlyReport,
                      icon: Icons.print_rounded,
                      isFullWidth: true,
                      onPressed:
                          _monthlyReleves.isEmpty || _configuration == null
                              ? null
                              : () async {
                                  final now = DateTime.now();
                                  await PdfService.generateMonthlyReport(
                                    releves: _monthlyReleves,
                                    locataires: _allLocataires,
                                    configuration: _configuration!,
                                    cites: _allCites,
                                    month: now.month,
                                    year: now.year,
                                    localizations: localizations,
                                  );
                                },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Statistiques du mois
              Text(
                'Statistiques du mois',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _isLoadingStats
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ModernStatsCard(
                                title: localizations.totalConsumption,
                                value:
                                    '${totalConsommation.toStringAsFixed(1)}',
                                subtitle: 'unités',
                                icon: Icons.water_drop_rounded,
                                iconColor: colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: ModernStatsCard(
                                title: localizations.totalAmount,
                                value: '${totalMontant.toStringAsFixed(0)}',
                                subtitle: _configuration?.devise ?? 'FCFA',
                                icon: Icons.account_balance_wallet_rounded,
                                iconColor: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ModernStatsCard(
                                title: localizations.totalPaidAmount,
                                value: '${totalPaidAmount.toStringAsFixed(0)}',
                                subtitle: _configuration?.devise ?? 'FCFA',
                                icon: Icons.check_circle_rounded,
                                iconColor: Colors.green,
                                trend: totalMontant > 0
                                    ? '${((totalPaidAmount / totalMontant) * 100).toInt()}%'
                                    : null,
                                isPositiveTrend: true,
                              ),
                            ),
                            Expanded(
                              child: ModernStatsCard(
                                title: localizations.totalUnpaidAmount,
                                value:
                                    '${totalUnpaidAmount.toStringAsFixed(0)}',
                                subtitle: _configuration?.devise ?? 'FCFA',
                                icon: Icons.pending_rounded,
                                iconColor: Colors.orange,
                                trend: totalMontant > 0
                                    ? '${((totalUnpaidAmount / totalMontant) * 100).toInt()}%'
                                    : null,
                                isPositiveTrend: false,
                              ),
                            ),
                          ],
                        ),
                        if (_monthlyReleves.isEmpty)
                          ModernCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    localizations.noReadingsForThisMonth,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

              const SizedBox(height: 32),

              // Menu principal
              Text(
                'Menu principal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildModernMenuCard(
                    context,
                    'Tableau de Bord',
                    Icons.dashboard_rounded,
                    colorScheme.primary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const EnhancedDashboardScreen()),
                    ),
                  ),
                  _buildModernMenuCard(
                    context,
                    localizations.cities,
                    Icons.location_city_rounded,
                    colorScheme.secondary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CitesScreen()),
                    ),
                  ),
                  _buildModernMenuCard(
                    context,
                    localizations.tenants,
                    Icons.people_rounded,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LocatairesScreen()),
                    ),
                  ),
                  _buildModernMenuCard(
                    context,
                    localizations.readings,
                    Icons.assessment_rounded,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RelevesScreen()),
                    ),
                  ),
                  _buildModernMenuCard(
                    context,
                    localizations.configuration,
                    Icons.settings_rounded,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ConfigurationScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
