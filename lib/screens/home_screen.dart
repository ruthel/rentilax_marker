import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
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
      appBar: AppBar(
        title: Text(localizations.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMonthlyStats,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${localizations.readingMonth}: ${DateFormat.MMMM('fr_FR').format(DateTime.now())}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _isLoadingStats
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${localizations.totalConsumption}: ${totalConsommation.toStringAsFixed(2)} unités'),
                                Text(
                                    '${localizations.totalAmount}: ${totalMontant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}'),
                                Text(
                                    '${localizations.totalPaidAmount}: ${totalPaidAmount.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}',
                                    style: TextStyle(color: Colors.green)),
                                Text(
                                    '${localizations.totalUnpaidAmount}: ${totalUnpaidAmount.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}',
                                    style: TextStyle(color: Colors.red)),
                                if (_monthlyReleves.isEmpty)
                                  Text(localizations.noReadingsForThisMonth),
                              ],
                            ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
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
                          icon: const Icon(Icons.print),
                          label: Text(localizations.printMonthlyReport),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      'Tableau de Bord',
                      Icons.dashboard,
                      Colors.indigo,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const EnhancedDashboardScreen()),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      localizations.cities,
                      Icons.location_city,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CitesScreen()),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      localizations.tenants,
                      Icons.people,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LocatairesScreen()),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      localizations.readings,
                      Icons.assessment,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RelevesScreen()),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      localizations.configuration,
                      Icons.settings,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ConfigurationScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
