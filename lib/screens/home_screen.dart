import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import 'enhanced_global_search_screen.dart';
import 'cites_screen.dart';
import 'enhanced_locataires_screen.dart';
import 'enhanced_releves_screen.dart';
import 'enhanced_configuration_screen.dart';
import 'advanced_dashboard_screen.dart';
import 'backup_sync_screen.dart';
import 'tarifs_management_screen.dart';
import '../models/releve.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../models/unit_type.dart';
import '../services/unit_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_stats_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/app_logo.dart';
import '../widgets/section_title.dart';
import '../utils/app_spacing.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final UnitService _unitService = UnitService();
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
      final units = await _unitService.getAllUnits();
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

    // Calcul des totaux pour les statistiques
    double totalMontant =
        _monthlyReleves.fold(0.0, (sum, item) => sum + item.montant);
    double totalPaidAmount = _monthlyReleves
        .where((releve) => releve.isPaid)
        .fold(0.0, (sum, item) => sum + item.montant);
    double totalUnpaidAmount = _monthlyReleves
        .where((releve) => !releve.isPaid)
        .fold(0.0, (sum, item) => sum + item.montant);

    return Stack(
      children: [
        Scaffold(
          appBar: ModernAppBar(
            title: localizations.appTitle,
            showBackButton: false,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: AppLogoIcon(size: 32),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnhancedGlobalSearchScreen(),
                    ),
                  );
                },
                tooltip: 'Recherche globale',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadMonthlyStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.page,
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
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
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
                                    DateFormat.MMMM('fr_FR')
                                        .format(DateTime.now())
                                        .toUpperCase(),
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
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

                  const SizedBox(height: AppSpacing.lg),

                  // Statistiques du mois
                  SectionTitle(text: localizations.monthlyStatistics),
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
                                    value: _getFormattedTotalConsumption(),
                                    subtitle: _getConsumptionSubtitle(),
                                    icon: _getConsumptionIcon(),
                                    iconColor: _getConsumptionColor(),
                                  ),
                                ),
                                Expanded(
                                  child: ModernStatsCard(
                                    title: localizations.totalAmount,
                                    value: totalMontant.toStringAsFixed(0),
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
                                    value: totalPaidAmount.toStringAsFixed(0),
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
                                    value: totalUnpaidAmount.toStringAsFixed(0),
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
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                  const SizedBox(height: AppSpacing.xl),

                  // Menu principal
                  SectionTitle(text: localizations.mainMenu),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.1,
                    children: [
                      _buildModernMenuCard(
                        context,
                        'Dashboard Analytics',
                        Icons.analytics_rounded,
                        colorScheme.primary,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AdvancedDashboardScreen()),
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
                              builder: (context) =>
                                  const EnhancedLocatairesScreen()),
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
                              builder: (context) =>
                                  const EnhancedRelevesScreen()),
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
                              builder: (context) =>
                                  const EnhancedConfigurationScreen()),
                        ),
                      ),
                      _buildModernMenuCard(
                        context,
                        'Gestion des Tarifs',
                        Icons.attach_money_rounded,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const TarifsManagementScreen()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ],
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedTotalConsumption() {
    if (_monthlyReleves.isEmpty) return '0';

    // Grouper par type d'unité
    final consumptionByType = <UnitType, double>{};

    for (final releve in _monthlyReleves) {
      final unitType = releve.unitType;
      consumptionByType[unitType] =
          (consumptionByType[unitType] ?? 0) + releve.consommation;
    }

    // Si un seul type, afficher la valeur directe
    if (consumptionByType.length == 1) {
      final entry = consumptionByType.entries.first;
      return entry.value.toStringAsFixed(1);
    }

    // Si plusieurs types, afficher le total général
    final total =
        consumptionByType.values.fold(0.0, (sum, value) => sum + value);
    return total.toStringAsFixed(1);
  }

  String _getConsumptionSubtitle() {
    if (_monthlyReleves.isEmpty) return 'unités';

    // Grouper par type d'unité
    final consumptionByType = <UnitType, double>{};

    for (final releve in _monthlyReleves) {
      final unitType = releve.unitType;
      consumptionByType[unitType] =
          (consumptionByType[unitType] ?? 0) + releve.consommation;
    }

    // Si un seul type, afficher l'unité appropriée
    if (consumptionByType.length == 1) {
      final unitType = consumptionByType.keys.first;
      return _getUnitSymbolByType(unitType);
    }

    // Si plusieurs types, afficher un résumé
    final types = consumptionByType.keys.map((type) => type.name).join(', ');
    return types;
  }

  IconData _getConsumptionIcon() {
    if (_monthlyReleves.isEmpty) return Icons.water_drop_rounded;

    // Déterminer le type d'unité le plus utilisé
    final typeCount = <UnitType, int>{};
    for (final releve in _monthlyReleves) {
      typeCount[releve.unitType] = (typeCount[releve.unitType] ?? 0) + 1;
    }

    if (typeCount.isEmpty) return Icons.water_drop_rounded;

    final mostUsedType =
        typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    switch (mostUsedType) {
      case UnitType.water:
        return Icons.water_drop_rounded;
      case UnitType.electricity:
        return Icons.electrical_services_rounded;
      case UnitType.gas:
        return Icons.local_fire_department_rounded;
    }
  }

  Color _getConsumptionColor() {
    if (_monthlyReleves.isEmpty) return Theme.of(context).colorScheme.primary;

    // Déterminer le type d'unité le plus utilisé
    final typeCount = <UnitType, int>{};
    for (final releve in _monthlyReleves) {
      typeCount[releve.unitType] = (typeCount[releve.unitType] ?? 0) + 1;
    }

    if (typeCount.isEmpty) return Theme.of(context).colorScheme.primary;

    final mostUsedType =
        typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    switch (mostUsedType) {
      case UnitType.water:
        return Colors.blue;
      case UnitType.electricity:
        return Colors.amber;
      case UnitType.gas:
        return Colors.orange;
    }
  }

  String _getUnitSymbolByType(UnitType type) {
    switch (type) {
      case UnitType.water:
        return 'm³';
      case UnitType.electricity:
        return 'kWh';
      case UnitType.gas:
        return 'm³';
    }
  }
}
